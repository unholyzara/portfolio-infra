
import argparse
import json
from pathlib import Path

import yaml


def normalize_list(value):
    if value is None:
        return []

    if isinstance(value, str):
        return [value]

    return list(value)


def normalize_dependencies(value):
    if isinstance(value, dict):
        return list(value.keys())

    return normalize_list(value)


def resolve_domain(values, domain):
    result = []

    for value in normalize_list(values):
        if domain:
            value = value.replace("DOMAIN", domain)

        result.append(value)

    return result


def parse_compose(compose_path, domain=None):
    with open(compose_path, encoding="utf-8") as file:
        compose = yaml.safe_load(file)

    nodes = []
    edges = []

    services = compose.get("services", {})

    # Docker Compose services
    for service_id, service in services.items():
        diagram = service.get("x-diagram", {})
        repository = service.get("x-repository-info", {})

        nodes.append({
            "id": service_id,
            "label": service_id,
            "origin": "container",
            "kind": diagram.get("kind", "service"),
            "stack": diagram.get("stack", ""),
            "profiles": normalize_list(service.get("profiles")),
            "hosts": resolve_domain(
                diagram.get("public"), domain
            ),
            "uses": normalize_list(diagram.get("uses")),
            "metadata": {
                "subdomain": service.get("x-subdomain"),
                "repository": repository
            }
        })

        # depends_on relationships
        for dependency in normalize_dependencies(
            service.get("depends_on")
        ):
            edges.append({
                "from": service_id,
                "to": dependency,
                "label": None,
                "type": "depends_on"
            })

        # Explicit service calls
        for target in normalize_list(diagram.get("calls")):
            edges.append({
                "from": service_id,
                "to": target,
                "label": None,
                "type": "calls"
            })

    # External platform nodes
    platform = compose.get("x-platform", {})

    for node_id, node in platform.get("nodes", {}).items():
        nodes.append({
            "id": node_id,
            "label": node.get("label", node_id),
            "origin": node.get("kind", "external"),
            "kind": node.get("kind", "external"),
            "stack": node.get("stack", ""),
            "profiles": [],
            "hosts": [],
            "uses": [],
            "metadata": {}
        })

    # Explicit platform edges
    for edge in platform.get("edges", []):
        source, target, *labels = edge

        edges.append({
            "from": source,
            "to": target,
            "label": labels[0] if labels else None,
            "type": "platform"
        })


    # Merge relationships between the same nodes
    merged_edges = {}

    for edge in edges:
        key = (edge["from"], edge["to"])

        if key not in merged_edges:
            merged_edges[key] = {
                "from": edge["from"],
                "to": edge["to"],
                "label": edge["label"],
                "types": []
            }

        if edge["type"] not in merged_edges[key]["types"]:
            merged_edges[key]["types"].append(edge["type"])

        # Preserve an explicit label
        if edge["label"] and not merged_edges[key]["label"]:
            merged_edges[key]["label"] = edge["label"]

    unique_edges = list(merged_edges.values())


    return {
        "project": compose.get("name", ""),
        "environments": compose.get("x-environments", []),
        "nodes": nodes,
        "edges": unique_edges
    }


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument("--compose", required=True)
    parser.add_argument("--domain")
    parser.add_argument(
        "--output",
        default="services.json"
    )

    args = parser.parse_args()

    result = parse_compose(
        args.compose,
        args.domain
    )

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)

    output.write_text(
        json.dumps(result, indent=2, ensure_ascii=False),
        encoding="utf-8"
    )

    print(f"Generated {output}")


if __name__ == "__main__":
    main()
