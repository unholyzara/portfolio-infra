import json
import os
import re
import subprocess
from datetime import datetime
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen


def run(*command):
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError(f"{command[0]} failed: {result.stderr.strip()}")
    return result.stdout


def normalize_branch(branch):
    lowercase = branch.translate(
        str.maketrans("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz")
    )
    return re.sub(r"[^a-z0-9._-]", "-", lowercase)


def get_active_branches(owner, repository):
    branches = set()
    page = 1
    owner = quote(owner, safe="")
    repository = quote(repository, safe="")

    while True:
        url = (
            f"https://api.github.com/repos/{owner}/{repository}/branches"
            f"?per_page=100&page={page}"
        )
        request = Request(
            url,
            headers={
                "Accept": "application/vnd.github+json",
                "User-Agent": "portfolio-infra-ecr-cleanup",
            },
        )
        try:
            with urlopen(request, timeout=30) as response:
                page_branches = json.load(response)
        except (HTTPError, URLError) as error:
            raise RuntimeError(
                f"Could not list branches for {owner}/{repository}: {error}"
            ) from error

        if not page_branches:
            break
        branches.update(normalize_branch(branch["name"]) for branch in page_branches)
        page += 1

    return branches


def cleanup_repository(owner, repository):
    active_branches = get_active_branches(owner, repository)
    image_details = json.loads(
        run(
            "aws",
            "ecr",
            "describe-images",
            "--repository-name",
            repository,
            "--filter",
            "tagStatus=TAGGED",
            "--output",
            "json",
        )
    ).get("imageDetails", [])

    tag_pattern = re.compile(
        r"^(?P<branch>.+)-(?P<timestamp>\d{2}-\d{2}-\d{4}_\d{2}-\d{2})$"
    )
    images_by_branch = {}
    stale_tags = set()

    for image in image_details:
        pushed_at = datetime.fromisoformat(
            image["imagePushedAt"].replace("Z", "+00:00")
        )
        for tag in image.get("imageTags", []):
            match = tag_pattern.fullmatch(tag)
            if not match:
                continue

            branch = match.group("branch")
            if branch not in active_branches:
                stale_tags.add(tag)
            else:
                images_by_branch.setdefault(branch, []).append((pushed_at, tag))

    for branch_images in images_by_branch.values():
        branch_images.sort(reverse=True)
        stale_tags.update(tag for _, tag in branch_images[5:])

    deleted_tags = sorted(stale_tags)
    for offset in range(0, len(deleted_tags), 100):
        batch = deleted_tags[offset : offset + 100]
        response = json.loads(
            run(
                "aws",
                "ecr",
                "batch-delete-image",
                "--repository-name",
                repository,
                "--image-ids",
                *[f"imageTag={tag}" for tag in batch],
                "--output",
                "json",
            )
        )
        failures = response.get("failures", [])
        if failures:
            raise RuntimeError(
                f"ECR failed to delete image tags from {repository}: {failures}"
            )

    print(
        f"{repository}: deleted {len(deleted_tags)} stale or excess image tag(s)."
    )


repositories = json.loads(os.environ["ECR_CLEANUP_REPOSITORIES"])
owner = os.environ["GITHUB_REPOSITORY_OWNER"]
for repository in repositories:
    cleanup_repository(owner, repository)
