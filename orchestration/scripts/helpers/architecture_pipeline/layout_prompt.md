You are laying out an architecture diagram. Your ONLY job is to set the "position" field of every node of one JSON file.

Files (paths relative to the repository root):
- TARGET (edit this file in place): orchestration/scripts/architecture/output/architecture.json
- REFERENCE (read only, do not modify): orchestration/diagram/architecture.json (previous layout, may be missing or outdated)
- ERRORS (read only, may not exist): orchestration/scripts/architecture/output/layout_errors.txt
  If it exists, it lists the problems of your previous attempt. Fix every one of them.

Grid convention: "position": [column, row], both non-negative integers, one node per cell. Columns go left to right, rows top to bottom.

How the diagram is drawn (this decides what a good layout is):
- Edges of type "runs_on" are NOT drawn. Ignore them when laying out. All other edges are drawn.
- An edge between two nodes in the SAME column is a straight vertical line from one card to the other. Every cell between them in that column must be EMPTY.
- An edge between nodes in DIFFERENT columns leaves the side of the source card, runs horizontally, makes one vertical step halfway between the two cards, and enters the side of the target card. Any card in a column strictly between the two columns can be crossed by this line, so keep connected nodes in ADJACENT columns whenever possible. If they are in columns further apart, the cells in between (in the rows of both nodes and, if the vertical step falls on them, in the rows between) must be empty.
- A line must never pass through another node's card. This is the main goal.

Layout rules:
1. Nodes that share an edge (excluding "runs_on") go in the same row or column, or in adjacent columns.
2. Data flows left to right: clients and DNS on the left, reverse proxy next, application containers in the middle, databases and jobs after that, AWS storage and monitoring on the right.
3. Keep the "container" nodes together, in the top rows. Put AWS infrastructure nodes (origin "aws": VPC, IAM, Elastic IP, EIP Association, EC2 Spot, grouped Route 53) in rows BELOW them, grouped logically.
4. Be compact: no empty columns or rows, no more rows and columns than needed.
5. Every position must be unique.
6. You may move any node, including those that appear in REFERENCE. Use REFERENCE as a starting point and change it only when needed to satisfy the rules above.
7. Be deterministic: if REFERENCE already satisfies all rules for a node, keep its position.

Hard rules:
- Add or change ONLY the "position" field of nodes. Do NOT change, add, remove or reorder anything else: no node, no edge, no id, no label, no metadata, no other key, no ordering of nodes or edges.
- Keep "position" right after "kind" in each node object when that key exists; otherwise append it at the end of the node. Keep 2-space indentation and a trailing newline.
- Do NOT create, modify or delete any other file.
- Do NOT run shell commands.
- When finished, reply with a single line: done