import argparse
import json
import sys
from pathlib import Path


def load_json(path, default=None):
    file = Path(path)
    if not file.exists():
        if default is not None:
            return default
        raise FileNotFoundError(path)
    return json.loads(file.read_text(encoding="utf-8"))


def strip_layout(architecture):
    clone = json.loads(json.dumps(architecture))
    clone.pop("host", None)
    for node in clone.get("nodes", []):
        node.pop("position", None)
    return clone


def canonical(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=False)


def validate(generated, edited, current):
    errors = []

    # 1. Nothing but positions changed.
    gen = strip_layout(generated)
    edi = strip_layout(edited)

    gen_nodes = {node["id"]: canonical(node) for node in gen["nodes"]}
    edi_nodes = {node["id"]: canonical(node) for node in edi["nodes"]}

    if gen_nodes != edi_nodes:
        changed = sorted(
            node_id
            for node_id in set(gen_nodes) | set(edi_nodes)
            if gen_nodes.get(node_id) != edi_nodes.get(node_id)
        )
        errors.append(f"Nodes changed beyond position: {changed}")

    gen_edges = sorted(canonical(edge) for edge in gen["edges"])
    edi_edges = sorted(canonical(edge) for edge in edi["edges"])

    if gen_edges != edi_edges:
        errors.append("Edges were modified")

    other_keys = {k for k in gen if k not in ("nodes", "edges")}
    for key in other_keys | {k for k in edi if k not in ("nodes", "edges")}:
        if gen.get(key) != edi.get(key):
            errors.append(f"Top-level key changed: {key}")

    # 2. Positions are well-formed and unique.
    seen = {}

    for node in edited["nodes"]:
        position = node.get("position")

        valid = (
            isinstance(position, list)
            and len(position) == 2
            and all(
                isinstance(value, int)
                and not isinstance(value, bool)
                and value >= 0
                for value in position
            )
        )

        if not valid:
            errors.append(
                f"Node {node['id']}: invalid or missing position {position!r}"
            )
            continue

        cell = tuple(position)

        if cell in seen:
            errors.append(
                f"Nodes {seen[cell]} and {node['id']} share cell {list(cell)}"
            )
        else:
            seen[cell] = node["id"]

    # 3. Existing nodes keep their position.
    current_positions = {
        node["id"]: node.get("position")
        for node in current.get("nodes", [])
        if node.get("position") is not None
    }

    for node in edited["nodes"]:
        previous = current_positions.get(node["id"])

        if previous is not None and node.get("position") != previous:
            errors.append(
                f"Node {node['id']} moved: {previous} -> {node.get('position')}"
            )

    return errors


def build_output(edited, current):
    host = current.get("host") or edited.get("host")
    rest = {key: value for key, value in edited.items() if key != "host"}

    return ({"host": host} if host else {}) | rest


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--generated", required=True)
    parser.add_argument("--edited", required=True)
    parser.add_argument("--current", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    generated = load_json(args.generated)
    edited = load_json(args.edited)
    current = load_json(args.current, default={})

    errors = validate(generated, edited, current)

    if errors:
        print("Layout validation failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        sys.exit(1)

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)

    output.write_text(
        json.dumps(build_output(edited, current), indent=2, ensure_ascii=False)
        + "\n",
        encoding="utf-8",
    )

    print(f"Generated {output} ({len(edited['nodes'])} nodes)")


if __name__ == "__main__":
    main()