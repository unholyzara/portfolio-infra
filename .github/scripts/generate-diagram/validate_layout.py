import argparse
import json
import sys
from pathlib import Path

# Must match diagram-layout.ts (CARD_WIDTH, GAP_X). Only the horizontal pitch matters:
# the check works on grid cells, so row heights are irrelevant.
CARD_WIDTH = 240
GAP_X = 64
PITCH = CARD_WIDTH + GAP_X

# Edge types the frontend does not draw (must match the filter in diagram-layout.ts).
DEFAULT_IGNORED_EDGE_TYPES = ("runs_on",)


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


def find_host(edges):
    counts = {}

    for edge in edges:
        if "runs_on" in edge.get("types", []):
            counts[edge["to"]] = counts.get(edge["to"], 0) + 1

    return max(counts, key=counts.get) if counts else None


def frame_box(edited, host_id):
    cells = [
        tuple(node["position"])
        for node in edited["nodes"]
        if node.get("origin") == "container" and node["id"] != host_id
    ]

    if not cells:
        return None

    cols = [col for col, _ in cells]
    rows = [row for _, row in cells]

    return min(cols), max(cols), min(rows), max(rows)


def edge_blockers(source, target):
    (c1, r1), (c2, r2) = source, target
    blockers = set()

    if c1 == c2:
        for row in range(min(r1, r2) + 1, max(r1, r2)):
            blockers.add((c1, row))
        return blockers

    # Work left to right.
    if c1 < c2:
        left, right, left_row, right_row = c1, c2, r1, r2
    else:
        left, right, left_row, right_row = c2, c1, r2, r1

    x_start = left * PITCH + CARD_WIDTH  # right edge of the left card
    x_end = right * PITCH                # left edge of the right card
    mid = (x_start + x_end) / 2

    for col in range(left + 1, right):   # columns strictly in between
        card_lo = col * PITCH
        card_hi = card_lo + CARD_WIDTH

        # First horizontal segment (left row): x_start -> mid
        if card_lo < mid and card_hi > x_start:
            blockers.add((col, left_row))

        # Second horizontal segment (right row): mid -> x_end
        if card_lo < x_end and card_hi > mid:
            blockers.add((col, right_row))

        # Vertical segment at mid, if it falls inside this column's card area.
        if card_lo <= mid <= card_hi:
            for row in range(min(left_row, right_row), max(left_row, right_row) + 1):
                blockers.add((col, row))

    return blockers


def check_structure(generated, edited):
    errors = []

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

    for key in {k for k in gen if k not in ("nodes", "edges")} | {
        k for k in edi if k not in ("nodes", "edges")
    }:
        if gen.get(key) != edi.get(key):
            errors.append(f"Top-level key changed: {key}")

    return errors


def check_positions(edited, host_id=None):
    errors = []
    seen = {}

    for node in edited["nodes"]:
        if node["id"] == host_id:
            continue  # drawn as the frame: its position is ignored

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

    return errors


def check_edge_crossings(edited, ignored_types, host_id=None):
    errors = []

    placed = [node for node in edited["nodes"] if node["id"] != host_id]
    cells = {tuple(node["position"]): node["id"] for node in placed}
    positions = {node["id"]: tuple(node["position"]) for node in placed}

    for edge in edited["edges"]:
        if set(edge.get("types", [])) & set(ignored_types):
            continue

        if host_id in (edge["from"], edge["to"]):
            continue  # checked by check_frame

        source, target = positions[edge["from"]], positions[edge["to"]]

        for cell in sorted(edge_blockers(source, target)):
            blocking = cells.get(cell)

            if blocking and blocking not in (edge["from"], edge["to"]):
                errors.append(
                    f"Edge {edge['from']} -> {edge['to']} passes through "
                    f"node {blocking} at cell {list(cell)}"
                )

    return errors


def check_frame(edited, host_id, ignored_types):
    errors = []

    if host_id is None:
        return errors

    box = frame_box(edited, host_id)

    if box is None:
        return errors

    min_col, max_col, min_row, max_row = box
    placed = {
        node["id"]: node
        for node in edited["nodes"]
        if node["id"] != host_id
    }

    for node_id, node in placed.items():
        col, row = node["position"]

        if (
            node.get("origin") != "container"
            and min_col <= col <= max_col
            and min_row <= row <= max_row
        ):
            errors.append(
                f"Node {node_id} at {[col, row]} is inside the frame area "
                f"(columns {min_col}-{max_col}, rows {min_row}-{max_row})"
            )

    for edge in edited["edges"]:
        if set(edge.get("types", [])) & set(ignored_types):
            continue

        if host_id not in (edge["from"], edge["to"]):
            continue

        other_id = edge["to"] if edge["from"] == host_id else edge["from"]
        other = placed.get(other_id)

        if other is None:
            continue

        col, row = other["position"]

        if row > max_row:
            adjacent, where = row == max_row + 1, f"in row {max_row + 1} (right below the frame)"
        elif row < min_row:
            adjacent, where = row == min_row - 1, f"in row {min_row - 1} (right above the frame)"
        elif col < min_col:
            adjacent, where = col == min_col - 1, f"in column {min_col - 1} (right at the left of the frame)"
        elif col > max_col:
            adjacent, where = col == max_col + 1, f"in column {max_col + 1} (right at the right of the frame)"
        else:
            continue  # inside the frame: already reported

        if not adjacent:
            errors.append(
                f"Edge {edge['from']} -> {edge['to']}: node {other_id} at {[col, row]} "
                f"must be {where}"
            )

    return errors


def check_locked_positions(edited, current):
    errors = []

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


def validate(generated, edited, current, ignored_types, lock_existing=False):
    host_id = find_host(edited["edges"])

    errors = check_structure(generated, edited)
    errors += check_positions(edited, host_id)

    # Geometry only makes sense on well-formed, unique positions.
    if not errors:
        errors += check_frame(edited, host_id, ignored_types)
        errors += check_edge_crossings(edited, ignored_types, host_id)

    if lock_existing:
        errors += check_locked_positions(edited, current)

    return errors


def build_output(edited, current):
    host = current.get("host") or edited.get("host")
    rest = {key: value for key, value in edited.items() if key != "host"}

    host_id = find_host(edited["edges"])
    box = frame_box(edited, host_id) if host_id else None

    if box:
        for node in rest["nodes"]:
            if node["id"] == host_id:
                node["position"] = [box[0], box[2]]

    return ({"host": host} if host else {}) | rest


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--generated", required=True)
    parser.add_argument("--edited", required=True)
    parser.add_argument("--current", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument(
        "--errors-file",
        help="Where to write the validation errors (removed on success).",
    )
    parser.add_argument(
        "--ignore-edge-types",
        nargs="*",
        default=list(DEFAULT_IGNORED_EDGE_TYPES),
        help="Edge types not drawn by the frontend, skipped by the crossing check.",
    )
    parser.add_argument(
        "--lock-existing",
        action="store_true",
        help="Fail if a node already in the current diagram changes position.",
    )
    args = parser.parse_args()

    generated = load_json(args.generated)
    edited = load_json(args.edited)
    current = load_json(args.current, default={})

    errors = validate(
        generated,
        edited,
        current,
        args.ignore_edge_types,
        args.lock_existing,
    )

    errors_file = Path(args.errors_file) if args.errors_file else None

    if errors:
        print("Layout validation failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)

        if errors_file:
            errors_file.write_text(
                "\n".join(f"- {error}" for error in errors) + "\n",
                encoding="utf-8",
            )

        sys.exit(1)

    if errors_file and errors_file.exists():
        errors_file.unlink()

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