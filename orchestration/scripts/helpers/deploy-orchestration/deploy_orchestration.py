#!/usr/bin/env python3
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml
from ..shared.compose_secrets import load_service_secrets, write_compose_override


def fail(message):
    print(message, file=sys.stderr)
    raise SystemExit(1)


if len(sys.argv) != 3 or sys.argv[1] not in {"beta", "prd"}:
    fail("Usage: deploy_orchestration.py <beta|prd> <compose-override-file>")

environment = sys.argv[1]
script_dir = Path(__file__).resolve().parent.parent
compose_dir = script_dir.parent
env_file = compose_dir / ".env"
service_compose_files = sorted((compose_dir.parent / "services").glob("*/compose.yml"))

if not env_file.is_file():
    fail(f"Missing Compose environment file: {env_file}")

env_values = {}
for line in env_file.read_text(encoding="utf-8").splitlines():
    key, separator, value = line.partition("=")
    if separator:
        env_values[key] = value

instance_environment = env_values.get("ENVIRONMENT", "")
if instance_environment != environment:
    fail(
        f"Instance environment {instance_environment!r} does not match "
        f"{environment!r}"
    )

project_name = env_values.get("PROJECT_NAME")
region = env_values.get("AWS_REGION")
if not project_name or not region:
    fail("PROJECT_NAME and AWS_REGION must be set in the Compose .env file")

services = {}
for service_compose_file in service_compose_files:
    with service_compose_file.open(encoding="utf-8") as source:
        compose = yaml.safe_load(source) or {}
    services.update(compose.get("services", {}))
service_secrets = {}
service_tags = {}
for service_name, config in services.items():
    if not str(config.get("image", "")).startswith("${ECR_REGISTRY}/"):
        continue

    parameter_name = f"/{project_name}/{environment}/deploy/{service_name}"
    result = subprocess.run(
        [
            "aws",
            "ssm",
            "get-parameter",
            "--region",
            region,
            "--name",
            parameter_name,
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
    tag = result.stdout.rstrip("\n")
    if not re.fullmatch(r"[A-Za-z0-9._-]+", tag):
        fail(f"Invalid image tag in SSM parameter {parameter_name}")
    service_tags[f"{service_name.upper().replace('-', '_')}_TAG"] = tag

try:
    service_secrets = load_service_secrets(
        compose_dir,
        services,
        project_name,
        environment,
        region,
    )
except (RuntimeError, ValueError) as error:
    fail(str(error))

lines = env_file.read_text(encoding="utf-8").splitlines()
all_secret_keys = {
    env_var
    for values in service_secrets.values()
    for env_var in values
}
updates = dict(service_tags)
update_keys = all_secret_keys | set(updates)
lines = [
    line for line in lines
    if line.partition("=")[0] not in update_keys
]
fd, temp_path = tempfile.mkstemp(prefix=".env.", dir=compose_dir)
try:
    os.fchmod(fd, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as target:
        target.writelines(f"{line}\n" for line in lines)
        target.writelines(f"{key}={value}\n" for key, value in updates.items())
    os.replace(temp_path, env_file)
finally:
    if os.path.exists(temp_path):
        os.unlink(temp_path)

write_compose_override(service_secrets, sys.argv[2])
