import argparse
import json
from pathlib import Path

# Deployment host -> (terraform module, resource type) of the node that runs containers.
DEPLOYMENT_HOSTS = {
    "ec2": ("ec2", "aws_spot_instance_request"),
}


def load_json(path):
    with Path(path).open(encoding="utf-8") as file:
        return json.load(file)


def build_deployment_edges(services, infrastructure):
    targets = {}

    for host, (module, resource_type) in DEPLOYMENT_HOSTS.items():
        for node in infrastructure.get("nodes", []):
            if (
                node.get("resource_type") == resource_type
                and module in node.get("modules", [])
            ):
                targets[host] = node["id"]
                break

    edges = []

    for node in services.get("nodes", []):
        if node.get("origin") != "container":
            continue

        for host in node.get("deployment_hosts", ["ec2"]):
            target = targets.get(host)

            if target:
                edges.append({
                    "from": node["id"],
                    "to": target,
                    "types": ["runs_on"],
                })

    return edges


# Fields the frontend (DiagramNode) expects on every node.
REQUIRED_LIST_FIELDS = ("profiles", "hosts", "uses")


def merge_architecture(services, infrastructure):
    nodes = services.get("nodes", []) + infrastructure.get("nodes", [])

    # Terraform nodes have no profiles/hosts/uses: normalize them to empty lists.
    for node in nodes:
        for field in REQUIRED_LIST_FIELDS:
            node.setdefault(field, [])
    edges = (
        services.get("edges", [])
        + infrastructure.get("edges", [])
        + build_deployment_edges(services, infrastructure)
    )

    # Verify node IDs are unique.
    node_ids = [node["id"] for node in nodes]
    duplicates = sorted({
        node_id for node_id in node_ids
        if node_ids.count(node_id) > 1
    })

    if duplicates:
        raise ValueError(f"Duplicate node IDs: {duplicates}")

    # Verify every edge references an existing node.
    node_id_set = set(node_ids)

    for edge in edges:
        for endpoint in ("from", "to"):
            if edge[endpoint] not in node_id_set:
                raise ValueError(
                    f"Edge references unknown node: "
                    f"{edge[endpoint]}"
                )

    return {
        "project": services.get("project"),
        "environments": services.get("environments", []),
        "nodes": nodes,
        "edges": edges,
    }


def main():
    parser = argparse.ArgumentParser(
        description="Merge Docker Compose and Terraform architecture"
    )

    parser.add_argument("--services", required=True)
    parser.add_argument("--infrastructure", required=True)
    parser.add_argument("--output", required=True)

    args = parser.parse_args()

    services = load_json(args.services)
    infrastructure = load_json(args.infrastructure)

    architecture = merge_architecture(services, infrastructure)

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with output_path.open("w", encoding="utf-8") as file:
        json.dump(architecture, file, indent=2, ensure_ascii=False)
        file.write("\n")

    print(f"Generated {output_path}")
    print(f"Nodes: {len(architecture['nodes'])}")
    print(f"Edges: {len(architecture['edges'])}")


if __name__ == "__main__":
    main()