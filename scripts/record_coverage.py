import csv
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

LIMIT = 30
HEADER = ["date", "run", "branch", "sha", "coverage"]
DEFAULT_BRANCH = "main"


def read_percent(report_path, kind):
    with open(report_path) as handle:
        data = json.load(handle)
    if kind == "python":
        return round(data["totals"]["percent_covered"], 2)
    if kind == "angular":
        return round(data["total"]["lines"]["pct"], 2)
    raise ValueError("Unknown report kind: " + kind)


def append_row(csv_path, row):
    csv_path.parent.mkdir(parents=True, exist_ok=True)
    is_new = not csv_path.exists()
    with open(csv_path, "a", newline="") as handle:
        writer = csv.writer(handle)
        if is_new:
            writer.writerow(HEADER)
        writer.writerow(row)


def load_rows(csv_path, branch):
    with open(csv_path, newline="") as handle:
        rows = [row for row in csv.DictReader(handle) if row["branch"] == branch]
    return rows[-LIMIT:]


def render(csv_path, service, branch):
    rows = load_rows(csv_path, branch)
    values = [float(row["coverage"]) for row in rows]
    labels = ", ".join('"#' + row["run"] + '"' for row in rows)
    low = max(0, int(min(values)) - 5)
    lines = [
        "## Coverage trend: " + service + " (" + branch + ")",
        "",
        "```mermaid",
        "xychart-beta",
        '    title "Coverage % - ' + service + '"',
        "    x-axis [" + labels + "]",
        '    y-axis "Coverage %" ' + str(low) + " --> 100",
        "    line [" + ", ".join(str(value) for value in values) + "]",
        "```",
        "",
        "Latest: " + str(values[-1]) + "%",
    ]
    return "\n".join(lines)


def render_svg(rows):
    values = [float(row["coverage"]) for row in rows]
    width, height, pad = 640, 240, 32
    low = max(0, int(min(values)) - 5)
    span = max(100 - low, 1)
    step = (width - 2 * pad) / max(len(values) - 1, 1)
    coordinates = [
        (pad + index * step, height - pad - (value - low) / span * (height - 2 * pad))
        for index, value in enumerate(values)
    ]
    points = " ".join(f"{x:.1f},{y:.1f}" for x, y in coordinates)
    circles = "".join(
        f'<circle cx="{x:.1f}" cy="{y:.1f}" r="3" fill="#2da44e"/>' for x, y in coordinates
    )
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">'
        '<rect width="100%" height="100%" fill="#ffffff"/>'
        f'<polyline fill="none" stroke="#2da44e" stroke-width="2" points="{points}"/>'
        f"{circles}"
        f'<text x="{pad}" y="20" font-family="sans-serif" font-size="12" fill="#24292f">'
        f"Coverage % (axis {low}-100), latest {values[-1]}%</text>"
        "</svg>"
    )


def main():
    service, kind, report, branch, sha, run, root = sys.argv[1:8]
    percent = read_percent(report, kind)
    csv_path = Path(root) / "coverage" / (service + ".csv")
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    append_row(csv_path, [now, run, branch, sha, percent])
    print(render(csv_path, service, branch))
    if branch == DEFAULT_BRANCH:
        svg_path = Path(root) / "coverage" / (service + ".svg")
        svg_path.write_text(render_svg(load_rows(csv_path, DEFAULT_BRANCH)))


if __name__ == "__main__":
    main()