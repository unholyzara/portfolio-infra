You are laying out an architecture diagram. Your ONLY job is to add a "position" field to every node of one JSON file.

Files (paths relative to the repository root):
- TARGET (edit this file in place): orchestration/scripts/architecture/output/architecture.json
- REFERENCE (read only, do not modify): orchestration/diagram/architecture.json

Task:
1. Read REFERENCE. It shows the grid convention: "position": [column, row], both non-negative integers, one node per cell.
2. In TARGET, add "position": [column, row] to EVERY node.
3. If a node id exists in REFERENCE, copy its position exactly. Do not move existing nodes.
4. For nodes that are not in REFERENCE (mostly AWS infrastructure: VPC, IAM, Elastic IP, EIP Association, EC2 Spot, Route 53 grouped node), choose free cells following these rules:
   - Data flows left to right: clients and DNS on the left, reverse proxy next, application containers in the middle, databases and jobs after that, AWS storage and monitoring on the right.
   - Put the infrastructure nodes in new rows BELOW the rows used by the container nodes, grouped logically (network/VPC, compute/EC2 Spot, IP/EIP, IAM, DNS), so that edges between them stay short and cross as little as possible.
   - Never reuse a cell. Every position must be unique.
5. Place "position" right after "kind" in each node object if that key exists; otherwise append it at the end of the node. Keep 2-space indentation and a trailing newline.

Hard rules:
- Do NOT change, add, remove or reorder anything else: no node, no edge, no id, no label, no metadata, no other key, no ordering of nodes or edges.
- Do NOT create, modify or delete any other file.
- Do NOT run shell commands.
- When finished, reply with a single line: done