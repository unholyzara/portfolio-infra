#!/usr/bin/env python3
import os
import re
import sys
import tempfile
from pathlib import Path

import yaml
from ..shared.compose_secrets import load_service_secrets, write_compose_override


def fail(message):
    print(message, file=sys.stderr)
    raise SystemExit(1)


if len(sys.argv) != 6:
    fail(
        "Usage: deploy_service.py <service> <beta|prd> <image-tag> "
        "<true|false> <compose-override-file>"
    )

service_name, environment, image_tag, run_migrations, override_file = sys.argv[1:]
if environment not in {"beta", "prd"}:
    fail(f"Invalid environment: {environment}")
if not re.fullmatch(r"[A-Za-z0-9._-]+", image_tag):
    fail("Invalid image tag")
if run_migrations not in {"true", "false"}:
    fail("Invalid run_migrations value")

compose_dir = Path(__file__).resolve().parents[2]
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

with (compose_dir.parent / "services" / service_name / "compose.yml").open(encoding="utf-8") as source:
    compose = yaml.safe_load(source)
service = compose.get("services", {}).get(service_name)
config_file = compose_dir.parent / "services" / service_name / "config.yml"
try:
    with config_file.open(encoding="utf-8") as source:
        service_config = yaml.safe_load(source) or {}
except FileNotFoundError:
    service_config = {}
repository_info = service_config.get("repository-info")
if not service or repository_info.get("deployable") is not True:
    fail(f"Unknown or non-deployable service: {service_name}")
if not str(service.get("image", "")).startswith("${ECR_REGISTRY}/"):
    fail(f"Service {service_name} does not use a custom ECR image")

secrets_file = compose_dir / "services" / service_name / "secrets.yml"
if secrets_file.is_file() and (
    not env_values.get("PROJECT_NAME") or not env_values.get("AWS_REGION")
):
    fail("PROJECT_NAME and AWS_REGION must be set in the Compose .env file")

try:
    secret_values = load_service_secrets(
        compose_dir,
        [service_name],
        env_values.get("PROJECT_NAME", ""),
        environment,
        env_values.get("AWS_REGION", ""),
    )
except (RuntimeError, ValueError) as error:
    fail(str(error))
secret_values = secret_values.get(service_name, {})

tag_key = f"{service_name.upper().replace('-', '_')}_TAG"
updates = {tag_key: image_tag}
updated_keys = {tag_key, *secret_values}
updated_lines = [
    line for line in lines
    if line.partition("=")[0] not in updated_keys
]
fd, temp_path = tempfile.mkstemp(prefix=".env.", dir=compose_dir)
try:
    os.fchmod(fd, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as target:
        target.writelines(f"{line}\n" for line in updated_lines)
        for key, value in updates.items():
            target.write(f"{key}={value}\n")
    os.replace(temp_path, env_file)
finally:
    if os.path.exists(temp_path):
        os.unlink(temp_path)

write_compose_override({service_name: secret_values}, override_file)
