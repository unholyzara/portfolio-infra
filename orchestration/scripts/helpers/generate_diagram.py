import re
import subprocess
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent.parent.parent
ORCHESTRATION_DIR = ROOT / "orchestration"
COMPOSE_FILE = ORCHESTRATION_DIR / "docker-compose.yml"
NGINX_CONF = ORCHESTRATION_DIR / "nginx" / "nginx.conf"
OUT_DIR = ROOT / "diagram"
ENTRYPOINT = "nginx"
PUBLIC_DOMAIN = "unholyzara.dev"
EC2_LABEL = "EC2 spot · Docker Compose"
GROUPS = {
    "edge": "DNS",
    "config": "Config e registry",
    "data": "Storage",
    "ops": "Monitoring",
}
PROXY_TARGET = re.compile(r"(?:proxy_pass|set\s+\$\w+)\s+http://([\w-]+)")


def load_compose(path):
    data = yaml.safe_load(path.read_text())
    services = {
        name: service
        for name, service in data["services"].items()
        if "x-diagram" in service
    }
    return services, data.get("x-platform", {})


def proxied_services(path):
    return set(PROXY_TARGET.findall(path.read_text()))


def validate(services):
    errors = []
    for name, service in services.items():
        calls = set(service["x-diagram"].get("calls", []))
        for target in calls:
            if target not in services:
                errors.append(f"{name}: calls unknown service {target}")
        if name == ENTRYPOINT:
            continue
        for target in service.get("depends_on", []):
            if target in services and target not in calls:
                errors.append(f"{name}: depends_on {target} not declared in calls")
    return errors


def validate_public(services, proxied):
    errors = []
    for name, service in services.items():
        public = service["x-diagram"].get("public")
        if public and name not in proxied:
            errors.append(f"{name}: public but not proxied by nginx")
    for name in sorted(proxied & services.keys()):
        if not services[name]["x-diagram"].get("public"):
            errors.append(f"{name}: proxied by nginx but no public in x-diagram")
    return errors


def validate_platform(services, platform):
    errors = []
    nodes = platform.get("nodes", {})
    known = set(services) | set(nodes)
    for name in sorted(nodes.keys() & services.keys()):
        errors.append(f"{name}: defined both as service and platform node")
    for name, node in nodes.items():
        if node.get("group") not in GROUPS:
            errors.append(f"{name}: unknown group {node.get('group')}")
    for edge in platform.get("edges", []):
        if len(edge) != 3:
            errors.append(f"edge {edge}: expected [source, target, label]")
            continue
        for endpoint in edge[:2]:
            if endpoint not in known:
                errors.append(f"edge {edge}: unknown node {endpoint}")
    return errors


def q(value):
    return f'"{value}"'


def service_node(name, service):
    diagram = service["x-diagram"]
    profiles = service.get("profiles", [])
    label = f'{name}\\n{diagram["stack"]}'
    classes = [diagram["kind"]]
    attrs = []
    if profiles:
        label += f'\\nprofile: {", ".join(profiles)}'
        classes.append("optional")
        attrs.append('style="filled,dashed"')
    attrs.append(f"label={q(label)}")
    attrs.append(f'class="{" ".join(classes)}"')
    return f'{q(name)} [{", ".join(attrs)}];'


def build_dot(services, platform):
    nodes = platform.get("nodes", {})
    lines = [
        "digraph architecture {",
        "rankdir=LR;",
        'bgcolor="transparent";',
        'graph [fontname="Helvetica-Bold", penwidth=3];',
        'node [shape=box, style=filled, penwidth=3, fontname="Helvetica-Bold"];',
        "edge [penwidth=2];",
        f'{q("browser")} [label="Browser", class="platform"];',
        f'{q("browser")} -> {q(ENTRYPOINT)};',
        "subgraph cluster_ec2 {",
        f"label={q(EC2_LABEL)};",
    ]
    for name, service in services.items():
        lines.append(service_node(name, service))
    lines.append("}")
    for group, title in GROUPS.items():
        members = {n: v for n, v in nodes.items() if v["group"] == group}
        if not members:
            continue
        lines.append(f"subgraph cluster_{group} {{")
        lines.append(f"label={q(title)};")
        for name, node in members.items():
            lines.append(f'{q(name)} [label={q(node["label"])}, class="cloud"];')
        lines.append("}")
    for name, service in services.items():
        diagram = service["x-diagram"]
        public = diagram.get("public", [])
        if public:
            label = "\\n".join(public).replace("DOMAIN", PUBLIC_DOMAIN)
            lines.append(f"{q(ENTRYPOINT)} -> {q(name)} [label={q(label)}];")
        for target in diagram.get("calls", []):
            lines.append(f"{q(name)} -> {q(target)};")
    for source, target, label in platform.get("edges", []):
        lines.append(f"{q(source)} -> {q(target)} [label={q(label)}];")
    lines.append("}")
    return "\n".join(lines) + "\n"


def render(dot_source, out_dir):
    out_dir.mkdir(exist_ok=True)
    (out_dir / "architecture.dot").write_text(dot_source)
    subprocess.run(
        ["dot", "-Tsvg", "-o", str(out_dir / "architecture.svg")],
        input=dot_source,
        text=True,
        check=True,
    )


if __name__ == "__main__":
    services, platform = load_compose(COMPOSE_FILE)
    errors = (
        validate(services)
        + validate_platform(services, platform)
        + validate_public(services, proxied_services(NGINX_CONF))
    )
    if errors:
        raise SystemExit("\n".join(errors))
    if "--check" not in sys.argv:
        render(build_dot(services, platform), OUT_DIR)