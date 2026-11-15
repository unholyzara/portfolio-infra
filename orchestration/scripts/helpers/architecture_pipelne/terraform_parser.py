
import argparse
import json
import re
from collections import defaultdict
from pathlib import Path


# Resources grouped into architectural components.
GROUPS = {
    "network": {
        "label": "VPC",
        "kind": "network",
        "stack": "AWS VPC",
        "types": {
            "aws_vpc",
            "aws_subnet",
            "aws_internet_gateway",
            "aws_route_table",
            "aws_route_table_association",
            "aws_security_group",
        },
    },
    "iam": {
        "label": "IAM",
        "kind": "security",
        "stack": "AWS IAM",
        "types": {
            "aws_iam_role",
            "aws_iam_instance_profile",
            "aws_iam_role_policy",
            "aws_iam_role_policy_attachment",
            "aws_iam_policy",
            "aws_iam_role_policy_attachments_exclusive",
        },
    },
    "dns": {
        "label": "Route 53",
        "kind": "dns",
        "stack": "AWS Route 53",
        "types": {
            "aws_route53_zone",
            "aws_route53_record",
        },
    },
}


# Important resources that should remain individual nodes.
INDIVIDUAL_RESOURCES = {
    "aws_spot_instance_request": {
        "label": "EC2 Spot",
        "kind": "compute",
        "stack": "AWS EC2 Spot",
    },
    "aws_instance": {
        "label": "EC2",
        "kind": "compute",
        "stack": "AWS EC2",
    },
    "aws_eip": {
        "label": "Elastic IP",
        "kind": "network",
        "stack": "AWS Elastic IP",
    },
    "aws_s3_bucket": {
        "label": "S3 Bucket",
        "kind": "storage",
        "stack": "AWS S3",
    },
    "aws_lambda_function": {
        "label": "Lambda",
        "kind": "compute",
        "stack": "AWS Lambda",
    },
    "aws_eip_association": {
        "label": "EIP Association",
        "kind": "network",
        "stack": "AWS EIP Association",
    },
}


def extract_resources(module):
    resources = []

    for resource in module.get("resources", []):
        resources.append(resource)

    for child in module.get("child_modules", []):
        resources.extend(extract_resources(child))

    return resources


def resource_module(address):
    match = re.search(r"module\.([a-zA-Z0-9_-]+)", address)
    return match.group(1) if match else "root"


def classify_resource(resource):
    resource_type = resource["type"]

    if resource_type == "aws_ec2_tag":
        return None

    for group_id, group in GROUPS.items():
        if resource_type in group["types"]:
            return {
                "id": group_id,
                "label": group["label"],
                "kind": group["kind"],
                "stack": group["stack"],
                "grouped": True,
            }

    individual = INDIVIDUAL_RESOURCES.get(resource_type)

    if individual:
        return {
            "id": resource["address"],
            **individual,
            "grouped": False,
        }

    # Unknown resources are preserved individually.
    return {
        "id": resource["address"],
        "label": resource_type.removeprefix("aws_"),
        "kind": "aws",
        "stack": resource_type,
        "grouped": False,
    }

def normalize_resource_address(address):
    address = re.sub(r'\[\d+\](?=\.)', '', address)
    address = re.sub(r'\["(?:\\.|[^"\\])*"\]', '', address)
    return address


def parse_dot(dot_path, resource_addresses):
    content = Path(dot_path).read_text(encoding="utf-8")

    pattern = re.compile(
        r'^\s*"((?:\\.|[^"\\])*)"\s*->\s*"((?:\\.|[^"\\])*)"',
        re.MULTILINE,
    )

    graph = defaultdict(set)

    for match in pattern.finditer(content):
        source, target = match.groups()

        source = source.removeprefix("[root] ").strip()
        target = target.removeprefix("[root] ").strip()

        graph[source].add(target)

    normalized_resources = defaultdict(list)

    for address in resource_addresses:
        normalized = normalize_resource_address(address)
        normalized_resources[normalized].append(address)

    edges = set()

    for resource in resource_addresses:
        normalized = normalize_resource_address(resource)
        expand_node = f"{normalized} (expand)"

        # Find the corresponding expand node.
        for source in graph:
            if source != expand_node:
                continue

            # Direct dependencies and dependencies through module inputs.
            queue = list(graph[source])
            visited = set()

            while queue:
                current = queue.pop()

                if current in visited:
                    continue

                visited.add(current)

                if current in resource_addresses:
                    if current != resource:
                        edges.add((resource, current))
                    continue

                # Traverse only module input/output nodes.
                if not (
                    ".var." in current
                    or ".output." in current
                ):
                    continue

                queue.extend(graph.get(current, []))

    return sorted(edges)

def build_infrastructure(plan_path, dot_path):
    plan = json.loads(
        Path(plan_path).read_text(encoding="utf-8")
    )

    root_module = plan.get(
        "planned_values", {}
    ).get("root_module", {})

    resources = extract_resources(root_module)

    nodes = {}
    resource_to_node = {}

    # Build architectural nodes.
    for resource in resources:
        classification = classify_resource(resource)

        if classification is None:
            continue

        address = resource["address"]

        node_id = classification["id"]

        resource_to_node[address] = node_id

        if node_id not in nodes:
            nodes[node_id] = {
                "id": node_id,
                "label": classification["label"],
                "origin": "aws",
                "kind": classification["kind"],
                "stack": classification["stack"],
                "modules": [],
                "resource_type": (
                    None if classification["grouped"]
                    else resource["type"]
                ),
                "metadata": {
                    "grouped": classification["grouped"],
                    "resources": [],
                },
            }

        nodes[node_id]["metadata"]["resources"].append({
            "address": address,
            "type": resource["type"],
            "module": resource_module(address),
        })
        module_name = resource_module(address)

        if module_name not in nodes[node_id]["modules"]:
            nodes[node_id]["modules"].append(module_name)

    # Parse dependencies.
    resource_addresses = set(resource_to_node)
    dot_edges = parse_dot(dot_path, resource_addresses)

    edges = {}

    for source, target in dot_edges:
        source_node = resource_to_node[source]
        target_node = resource_to_node[target]

        if source_node == target_node:
            continue

        # Terraform DOT: source depends on target.
        # Reverse the edge to represent dependency flow.
        key = (target_node, source_node)

        if key not in edges:
            edges[key] = {
                "from": target_node,
                "to": source_node,
                "types": ["terraform_dependency"],
                "metadata": {
                    "terraform_dependencies": []
                },
            }

        edges[key]["metadata"]["terraform_dependencies"].append({
            "source": source,
            "target": target,
        })

    # Sort resources and edges for deterministic output.
    for node in nodes.values():
        node["metadata"]["resources"].sort(
            key=lambda item: item["address"]
        )

    return {
        "project": "portfolio",
        "terraform_version": plan.get("terraform_version"),
        "nodes": sorted(
            nodes.values(),
            key=lambda item: item["id"]
        ),
        "edges": sorted(
            edges.values(),
            key=lambda item: (item["from"], item["to"])
        ),
    }


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--plan",
        required=True,
    )

    parser.add_argument(
        "--graph",
        required=True,
    )

    parser.add_argument(
        "--output",
        default="infrastructure.json",
    )

    args = parser.parse_args()

    result = build_infrastructure(
        args.plan,
        args.graph,
    )

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)

    output.write_text(
        json.dumps(result, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    print(f"Generated {output}")
    print(f"Nodes: {len(result['nodes'])}")
    print(f"Edges: {len(result['edges'])}")


if __name__ == "__main__":
    main()
