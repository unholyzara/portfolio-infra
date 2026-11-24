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


if len(sys.argv) != 2 or sys.argv[1] not in {"beta", "prd"}:
    fail("Usage: deploy_orchestration.py <beta|prd>")

environment = sys.argv[1]
script_dir = Path(__file__).resolve().parent
compose_dir = script_dir.parent
env_file = compose_dir / ".env"
compose_file = compose_dir / "docker-compose.yml"

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

with compose_file.open(encoding="utf-8") as source:
    compose = yaml.safe_load(source)

services = compose.get("services", {})
standard_services = [
    service_name
    for service_name, config in services.items()
    if not str(config.get("image", "")).startswith("${ECR_REGISTRY}/")
]
custom_services_with_secrets = [
    service_name
    for service_name, config in services.items()
    if str(config.get("image", "")).startswith("${ECR_REGISTRY}/")
    and (compose_dir / "services" / service_name / "secrets.yml").is_file()
]
secret_values = {}
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

for service_name in [*standard_services, *custom_services_with_secrets]:
    secrets_file = compose_dir / "services" / service_name / "secrets.yml"
    if not secrets_file.is_file():
        continue

    # Custom services also need their secrets when the full stack is first started.
    # Their standalone deploy workflow refreshes the same values on later deployments.
    with secrets_file.open(encoding="utf-8") as source:
        service_secrets = yaml.safe_load(source)
    if not isinstance(service_secrets, dict):
        fail(f"{secrets_file} must contain a mapping")

    for env_var, suffix in service_secrets.items():
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

lines = env_file.read_text(encoding="utf-8").splitlines()
updates = {**service_tags, **secret_values}
update_keys = set(updates)
lines = [
    line for line in lines
    if line.partition("=")[0] not in update_keys
]
fd, temp_path = tempfile.mkstemp(prefix=".env.", dir=compose_dir)
try:
    os.fchmod(fd, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as target:
        target.writelines(f"{line}\n" for line in lines)
        target.writelines(f"{key}={quote_env_value(value)}\n" for key, value in updates.items())
    os.replace(temp_path, env_file)
finally:
    if os.path.exists(temp_path):
        os.unlink(temp_path)

profile_args = ["--profile", "monitoring"] if environment == "prd" else []
subprocess.run(["docker", "compose", *profile_args, "pull"], cwd=compose_dir, check=True)
subprocess.run(
    ["docker", "compose", *profile_args, "up", "-d"],
    cwd=compose_dir,
    check=True,
)
