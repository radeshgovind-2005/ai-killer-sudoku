# Report Notes — State Representation

> This note is for the report section on design decisions.

## Decision: Flat 81-element list, row-major order

Both the Prolog and Python implementations use the same logical representation:
- A flat list/array of 81 integers
- Index formula: `(row - 1) * 9 + (col - 1)` (1-indexed rows and cols)
- Value `0` represents an empty cell

## Why this representation

**Alternatives considered:**
1. Nested 9-element lists (list of rows) — row access is O(1) but column and box access require traversal
2. Dictionary `{(row,col): value}` — clean interface but overhead per access
3. Flat list (chosen) — uniform access pattern, works naturally with Prolog's `nth0/3`

**Reason for flat list:**
- `nth0(Index, Board, Value)` in Prolog directly accesses any cell in O(N) — same as nested
- Row extraction is a sublist slice; column is a findall; box uses computed offsets — all consistent
- Avoids nested list operations in Prolog which would require `nth0` twice (once for row, once for element)
- Mirrors naturally to Python's flat list, making the board format shareable as text files
- Forward checking and constraint propagation work on indices, not nested structures

**Trade-off acknowledged:**
- Column access is O(81) not O(1) — acceptable because columns are accessed at most once per placement, and 81 operations are negligible vs. branching factor of search

## Shared text format

The `.txt` puzzle files use the same format for both Prolog and Python:
- 9 rows, 9 characters each (or 81 characters, no separators)
- Digits `1-9` for given cells, `0` or `.` for empty cells
- Both `board_from_string` predicates strip non-relevant characters identically

This means a single puzzle file can drive all four solvers without conversion.

## Implications for search algorithms

- **DFID / A\***: state is a Board (flat list). Each node in the search tree is a new list with one more cell filled. In Prolog, `set_cell` creates a new list via `nth0/3` unification — this is the main memory allocation per node.
- **SA / GA**: state is also a complete Board. Operators produce new boards (Python list copy + swap). The flat representation makes the box-swap operator trivial: compute box start indices, select two positions, swap.
