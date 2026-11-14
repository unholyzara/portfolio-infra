import json
import re
import sys
from pathlib import Path

import yaml

ORCHESTRATION = Path(__file__).resolve().parent.parent.parent
COMPOSE_FILE = ORCHESTRATION / "docker-compose.yml"
NGINX_CONF = ORCHESTRATION / "nginx" / "nginx.conf"
OUT_DIR = ORCHESTRATION / "diagram"
ENTRYPOINT = "nginx"
PUBLIC_DOMAIN = "unholyzara.dev"
HOST_LABEL = "EC2 spot · Docker Compose"
PLATFORM_KINDS = {"client", "aws"}
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
        if node.get("kind") not in PLATFORM_KINDS:
            errors.append(f"{name}: unknown kind {node.get('kind')}")
    for edge in platform.get("edges", []):
        if len(edge) != 3:
            errors.append(f"edge {edge}: expected [source, target, label]")
            continue
        for endpoint in edge[:2]:
            if endpoint not in known:
                errors.append(f"edge {edge}: unknown node {endpoint}")
    return errors


def validate_positions(services, platform):
    errors = []
    seen = {}
    entries = [(name, service["x-diagram"]) for name, service in services.items()]
    entries += list(platform.get("nodes", {}).items())
    for name, entry in entries:
        position = entry.get("position")
        if not isinstance(position, list) or len(position) != 2:
            errors.append(f"{name}: position must be [col, row]")
            continue
        key = tuple(position)
        if key in seen:
            errors.append(f"{name}: same position as {seen[key]}")
        seen[key] = name
    return errors


def build_graph(services, platform):
    nodes = []
    edges = []
    for name, service in services.items():
        diagram = service["x-diagram"]
        hosts = [host.replace("DOMAIN", PUBLIC_DOMAIN) for host in diagram.get("public", [])]
        nodes.append(
            {
                "id": name,
                "label": name,
                "stack": diagram["stack"],
                "origin": "container",
                "kind": diagram["kind"],
                "position": diagram["position"],
                "profiles": service.get("profiles", []),
                "hosts": hosts,
                "uses": diagram.get("uses", []),
            }
        )
        if hosts:
            edges.append({"from": ENTRYPOINT, "to": name, "label": None})
        for target in diagram.get("calls", []):
            edges.append({"from": name, "to": target, "label": None})
    for name, node in platform.get("nodes", {}).items():
        nodes.append(
            {
                "id": name,
                "label": node["label"],
                "stack": node.get("stack", ""),
                "origin": node["kind"],
                "kind": node["kind"],
                "position": node["position"],
                "profiles": [],
                "hosts": [],
                "uses": [],
            }
        )
    for source, target, label in platform.get("edges", []):
        edges.append({"from": source, "to": target, "label": label})
    return {"host": HOST_LABEL, "nodes": nodes, "edges": edges}


def render(graph, out_dir):
    out_dir.mkdir(exist_ok=True)
    text = json.dumps(graph, indent=2, ensure_ascii=False) + "\n"
    (out_dir / "architecture.json").write_text(text)


if __name__ == "__main__":
    services, platform = load_compose(COMPOSE_FILE)
    errors = (
        validate(services)
        + validate_platform(services, platform)
        + validate_positions(services, platform)
        + validate_public(services, proxied_services(NGINX_CONF))
    )
    if errors:
        raise SystemExit("\n".join(errors))
    if "--check" not in sys.argv:
        render(build_graph(services, platform), OUT_DIR)