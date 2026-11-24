#!/usr/bin/env python3
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml


def fail(message):
    print(message, file=sys.stderr)
    raise SystemExit(1)


def quote_env_value(value):
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


if len(sys.argv) != 5:
    fail("Usage: deploy_service.py <service> <beta|prd> <image-tag> <true|false>")

service_name, environment, image_tag, run_migrations = sys.argv[1:]
if environment not in {"beta", "prd"}:
    fail(f"Invalid environment: {environment}")
if not re.fullmatch(r"[A-Za-z0-9._-]+", image_tag):
    fail("Invalid image tag")
if run_migrations not in {"true", "false"}:
    fail("Invalid run_migrations value")

compose_dir = Path(__file__).resolve().parent.parent
env_file = compose_dir / ".env"
with env_file.open(encoding="utf-8") as source:
    lines = source.read().splitlines()
env_values = {}
for line in lines:
    key, separator, value = line.partition("=")
    if separator:
        env_values[key] = value
if env_values.get("ENVIRONMENT") != environment:
    fail("Target environment does not match the EC2 environment")

with (compose_dir / "docker-compose.yml").open(encoding="utf-8") as source:
    compose = yaml.safe_load(source)
service = compose.get("services", {}).get(service_name)
if not service or service.get("x-repository-info", {}).get("deployable") is not True:
    fail(f"Unknown or non-deployable service: {service_name}")
if not str(service.get("image", "")).startswith("${ECR_REGISTRY}/"):
    fail(f"Service {service_name} does not use a custom ECR image")

secrets_file = compose_dir / "services" / service_name / "secrets.yml"
secret_values = {}
if secrets_file.is_file():
    with secrets_file.open(encoding="utf-8") as source:
        secret_mapping = yaml.safe_load(source)
    if not isinstance(secret_mapping, dict):
        fail(f"{secrets_file} must contain a mapping")

    project_name = env_values.get("PROJECT_NAME")
    region = env_values.get("AWS_REGION")
    if not project_name or not region:
        fail("PROJECT_NAME and AWS_REGION must be set in the Compose .env file")

    for env_var, suffix in secret_mapping.items():
        if not isinstance(env_var, str) or not re.fullmatch(r"[A-Z_][A-Z0-9_]*", env_var):
            fail(f"Invalid environment variable in {secrets_file}: {env_var!r}")
        if not isinstance(suffix, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]*", suffix):
            fail(f"Invalid SSM secret suffix for {env_var} in {secrets_file}")

        parameter_name = f"/{project_name}/{environment}/secret/{suffix}"
        result = subprocess.run(
            [
                "aws",
                "ssm",
                "get-parameter",
                "--region",
                region,
                "--name",
                parameter_name,
                "--with-decryption",
                "--query",
                "Parameter.Value",
                "--output",
                "text",
            ],
            check=False,
            capture_output=True,
            text=True,
        )
        if result.returncode:
            fail(f"Unable to read SSM parameter {parameter_name}: {result.stderr.strip()}")
        value = result.stdout.rstrip("\n")
        if "\n" in value or "\r" in value:
            fail(f"SSM parameter {parameter_name} contains a newline")
        if "$" in value or "\\" in value:
            fail(f"SSM parameter {parameter_name} contains characters unsupported by Compose .env")
        secret_values[env_var] = value

tag_key = f"{service_name.upper().replace('-', '_')}_TAG"
updates = {tag_key: image_tag, **secret_values}
updated_lines = [
    line for line in lines
    if line.partition("=")[0] not in updates
]
fd, temp_path = tempfile.mkstemp(prefix=".env.", dir=compose_dir)
try:
    os.fchmod(fd, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as target:
        target.writelines(f"{line}\n" for line in updated_lines)
        for key, value in updates.items():
            target.write(f"{key}={quote_env_value(value)}\n")
    os.replace(temp_path, env_file)
finally:
    if os.path.exists(temp_path):
        os.unlink(temp_path)

subprocess.run(["docker", "compose", "pull", service_name], cwd=compose_dir, check=True)
if run_migrations == "true" and service_name == "api":
    subprocess.run(
        ["docker", "compose", "run", "--rm", service_name, "python", "manage.py", "migrate"],
        cwd=compose_dir,
        check=True,
    )
subprocess.run(["docker", "compose", "up", "-d", service_name], cwd=compose_dir, check=True)
