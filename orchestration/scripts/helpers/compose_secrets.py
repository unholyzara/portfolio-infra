import os
import re
import subprocess
from pathlib import Path

import yaml


def load_service_secrets(compose_dir, services, project_name, environment, region):
    secrets_by_service = {}
    for service_name in services:
        secrets_file = compose_dir / "services" / service_name / "secrets.yml"
        if not secrets_file.is_file():
            continue

        with secrets_file.open(encoding="utf-8") as source:
            mapping = yaml.safe_load(source)
        if not isinstance(mapping, dict):
            raise ValueError(f"{secrets_file} must contain a mapping")

        values = {}
        for env_var, suffix in mapping.items():
            if not isinstance(env_var, str) or not re.fullmatch(r"[A-Z_][A-Z0-9_]*", env_var):
                raise ValueError(f"Invalid environment variable in {secrets_file}: {env_var!r}")
            if not isinstance(suffix, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]*", suffix):
                raise ValueError(f"Invalid SSM secret suffix for {env_var} in {secrets_file}")

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
                raise RuntimeError(
                    f"Unable to read SSM parameter {parameter_name}: {result.stderr.strip()}"
                )
            value = result.stdout.rstrip("\n")
            if "\n" in value or "\r" in value:
                raise ValueError(f"SSM parameter {parameter_name} contains a newline")
            values[env_var] = value
        secrets_by_service[service_name] = values

    return secrets_by_service


def write_compose_override(secrets_by_service, output_path):
    override = {
        "services": {
            service_name: {
                "environment": {
                    key: value.replace("$", "$$")
                    for key, value in values.items()
                }
            }
            for service_name, values in secrets_by_service.items()
            if values
        }
    }
    fd = os.open(output_path, os.O_WRONLY | os.O_TRUNC)
    os.fchmod(fd, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as target:
        yaml.safe_dump(override, target, sort_keys=False)
