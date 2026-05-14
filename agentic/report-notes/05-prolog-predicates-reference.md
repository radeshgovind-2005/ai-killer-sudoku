# Report Notes — Prolog Predicates Reference

> The report must explain the main Prolog predicates and data structures. Draft these descriptions here as you implement — it is easier to write while the code is fresh.

---

## Data Structures

### Board
- Type: flat list of 81 integers
- Values: 0 (empty), 1–9 (given or placed)
- Access: `cell(Board, Row, Col, Value)` where Row, Col ∈ {1..9}
- Index: `(Row - 1) * 9 + (Col - 1)` via `nth0/3`

### Cage (Killer Sudoku only)
- Type: compound term `cage(Sum, Cells)`
- `Sum`: integer, the target sum for this cage
- `Cells`: list of `(Row, Col)` pairs identifying which cells belong to the cage
- A puzzle's cage set is passed as a list: `[cage(15, [(1,1),(1,2)]), ...]`

---

## Core Predicates (sudoku.pl)

### `cell(+Board, +Row, +Col, ?Value)`
Accesses or unifies the value at position (Row, Col). Used everywhere in constraint checking and search.

### `set_cell(+Board, +Row, +Col, +Value, -NewBoard)`
Returns a new board with Value placed at (Row, Col). This is the operator in state-space search — each call represents one edge in the search tree.

### `valid_placement(+Board, +Row, +Col, +Value)`
True if placing Value at (Row, Col) does not violate any row, column, or box constraint. Core pruning predicate used in DFID and A*.

### `empty_cells(+Board, -Cells)`
Returns the list of `(Row, Col)` pairs where Board has value 0. Used to enumerate candidates at each search node.

### `candidates(+Board, +Row, +Col, -Candidates)`
Returns the list of values 1–9 that are valid at (Row, Col) given current board state. Used in MRV and A* heuristic.

### `solved(+Board)`
True if the board has no empty cells and passes `valid/1`. Goal test for both DFID and A*.

---

## DFID Predicates (dfid.pl)

### `solve_dfid(+Board, -Solution)`
Entry point. Determines initial depth bound (number of empty cells), then calls `dfid/3` with increasing bounds.

### `dfid(+Board, +DepthLimit, -Solution)`
Recursive DFS with depth bound. Base case: Board is solved. Recursive case: pick next empty cell (MRV), try each candidate, check placement validity, recurse with decremented depth.

### `next_empty(+Board, -Row, -Col)` (MRV version)
Finds the empty cell with the fewest valid candidates. Ties broken by position. This single predicate has the most impact on search performance.

---

## A* Predicates (astar.pl)

### `solve_astar(+Board, -Solution)`
Entry point. Initializes open list as a singleton heap, closed list as empty.

### `astar(+Open, +Closed, -Solution)`
Main loop. Extracts minimum-f node from Open. If solved, return. Otherwise expand and recurse.

### `h(+Board, -H)`
Heuristic function. Returns sum of (|candidates(cell)| - 1) over all empty cells.

### `expand(+Board, +G, +OpenIn, -OpenOut)`
Generates all valid successor states of Board (one per valid candidate per empty cell picked by MRV), computes f = g+1 + h for each, inserts into heap.

---

## Killer Sudoku Predicates (killer_sudoku.pl)

### `valid_cage(+Board, +cage(Sum, Cells))`
For a completely filled cage: verifies that the values of Cells sum to Sum and are all different.

### `partial_cage_check(+Board, +cage(Sum, Cells))`
For a partially filled cage during search: verifies the partial sum does not exceed Sum, and the remaining empty cells can still reach Sum (upper and lower bounds check).

### `valid_cages(+Board, +Cages)`
`maplist(valid_cage(Board), Cages)` — checks all cages. Used in the goal test.

### `partial_cages_check(+Board, +Cages)`
`maplist(partial_cage_check(Board), Cages)` — used during search to prune.

---

## Notes on Prolog-Specific Choices

### Backtracking as search
DFID uses Prolog's native backtracking instead of an explicit stack. When `valid_placement` fails, Prolog automatically undoes the `set_cell` and tries the next candidate via `between(1, 9, Value)`. This is not a workaround — it is the idiomatic Prolog approach.

### Determinism vs non-determinism
`solve_dfid/2` is made deterministic with `!` (cut) after the first solution is found. Without the cut, Prolog would backtrack into alternative solutions. For this assignment, finding any one solution is sufficient.

### `findall` for list comprehension
`empty_cells`, `candidates`, and `box_cells` use `findall/3` to collect results into lists. This is idiomatic Prolog — it is how you do list comprehension. The result is always deterministic (findall never fails).
