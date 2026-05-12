# AI Killer Sudoku — ISEL IA 2025/2026

**Course**: Inteligência Artificial — Semestre de Verão 2025/2026
**Institution**: ISEL — Instituto Superior de Engenharia de Lisboa
**Professor**: Nuno Leite
**Deadline**: 19 May 2026 at 23:59 (submit via Moodle)
**Stack**: Prolog (SWI-Prolog) + Python 3 + VSCode

---

## What This Is

You are building automated solvers for Sudoku and Killer Sudoku. Not one solver. Four, using fundamentally different approaches from two paradigms: **search in state space** and **search in solution space (optimization)**. The assignment forces you to understand why these paradigms exist, when each is appropriate, and what their trade-offs are. The Prolog requirement is not optional and is not a joke.

The four algorithms:

| Algorithm | Type | Language |
|---|---|---|
| Depth-First Iterative Deepening (DFID) | Uninformed search | Prolog |
| A* (Best-First Search) | Informed search | Prolog |
| Simulated Annealing (SA) | Optimization | Python |
| Genetic Algorithm (GA) | Optimization | Python |

---

## Theory — Read This Before Writing a Single Line

### 1. Sudoku as a Problem

Classic 9×9 Sudoku: fill the grid so that every row, column, and 3×3 box contains each digit from 1 to 9 exactly once. The sum of any complete row, column, or box is always 45. A well-formed puzzle has exactly one solution.

The **state** is a partially filled 9×9 grid. The **goal state** is a fully and validly filled grid. An **operator** assigns a digit to an empty cell.

### 2. Killer Sudoku

Killer Sudoku adds **cages** on top of the standard Sudoku rules. A cage is a group of cells enclosed by a dotted border with a small target sum shown in the top-left corner. The rules:

- All standard Sudoku constraints apply (rows, columns, 3×3 boxes are all unique 1–9)
- Within each cage: all values are **unique** (no repeats inside a cage)
- Within each cage: values must **sum to the cage total**

This makes Killer Sudoku strictly harder because you have more constraints propagating simultaneously. The cage constraint is an additional pruning opportunity — use it.

### 3. State Space Search

You are exploring a tree of partial assignments. Each node is a board state. Each edge is placing one digit in one cell.

**Why does state representation matter?** Because your operators derive from it. A flat 81-element list makes indexing clean in Prolog. A 9×9 nested list makes row access O(1) but column/box access O(n). Choose deliberately and document why.

#### 3a. DFID — Depth-First Iterative Deepening

DFS has the memory efficiency of depth-first (O(depth)) but completeness of breadth-first. It works by running DFS with increasing depth limits: 1, 2, 3, ... until a solution is found.

For Sudoku this translates to: depth = number of cells assigned. The depth limit starts at the number of already-filled cells and grows to 81. In practice this is just DFS with constraint checking because the depth is bounded by the grid itself. The "iterative deepening" is meaningful here mostly when your branching is constrained by forward checking — each call prunes the search space before recursing.

**In Prolog**, this is natural: you recurse, try a digit, check constraints, backtrack on failure. The built-in backtracking mechanism is your search engine. Do not fight it.

Key Prolog predicates you will need:
```prolog
% Check a value is valid at position (Row, Col)
valid_placement(Board, Row, Col, Value)

% Get all empty cells
empty_cells(Board, Cells)

% Apply an operator: place Value at (Row, Col)
place_value(Board, Row, Col, Value, NewBoard)

% Goal test
solved(Board)
```

#### 3b. A* — Best-First Informed Search

A* expands the node with the lowest `f(n) = g(n) + h(n)`:
- `g(n)` = cost to reach node `n` (number of cells placed so far, or 0 for unit-cost)
- `h(n)` = heuristic estimate of remaining cost (must be **admissible**: never overestimates)

**Admissible heuristic for Sudoku**: count the number of empty cells. This is admissible because each empty cell requires at least one assignment to reach a solution. You cannot solve faster than filling every empty cell exactly once.

A stronger heuristic: for each empty cell, compute the number of valid candidates. Sum across all empty cells. This is still admissible and gives A* better guidance.

**In Prolog**, you maintain a priority queue (open list) sorted by `f`. SWI-Prolog has `library(heaps)` or you implement your own ordered insertion. The closed list prevents re-expansion.

```prolog
% f = g + h
f_value(Board, G, F) :-
    h(Board, H),
    F is G + H.

% Admissible heuristic: count empty cells
h(Board, H) :-
    count_empty(Board, H).
```

A* is **complete** and **optimal** given an admissible heuristic. It is memory-intensive — the open list can be huge. For hard Sudoku puzzles, A* without constraint propagation is impractical. Add forward checking (MRV heuristic — Minimum Remaining Values) to prune.

### 4. Search in Solution Space (Optimization)

Instead of building a solution step by step from scratch, you start with a **complete but likely invalid** assignment and **evolve it** toward a valid solution. The search space is the set of all complete 81-cell assignments, not partial states.

**Cost function / fitness**: count the number of constraint violations. Goal: minimize violations to 0.

This reframing enables SA and GA, which are not complete but scale much better to hard instances.

#### 4a. Simulated Annealing (SA)

SA is a probabilistic local search algorithm inspired by the physical annealing process in metallurgy. It avoids getting stuck in local minima by accepting worse solutions with a probability that decreases over time (as "temperature" T decreases).

**Algorithm**:
```
1. Generate initial solution S (complete assignment, pre-filled cells fixed)
2. Set temperature T = T_initial
3. While T > T_min:
    a. Generate neighbor S' by applying a random operator to S
    b. Compute delta = cost(S') - cost(S)
    c. If delta < 0: accept S' (improvement)
    d. If delta >= 0: accept S' with probability exp(-delta / T)
    e. Decrease T: T = T * cooling_rate
4. Return best solution found
```

**State representation for SA**: a complete 9×9 grid where pre-filled (given) cells are fixed. Only mutable cells are touched by operators.

**Operator (neighbor generation)**: within a 3×3 box, swap two non-given cells. This preserves the uniqueness constraint within boxes, reducing the search space to row/column violations only. This is the most effective operator for Sudoku SA.

**Cost function**:
```python
def cost(board):
    violations = 0
    for i in range(9):
        violations += 9 - len(set(board[i]))          # row duplicates
        violations += 9 - len(set(board[:, i]))       # column duplicates
    return violations
    # Boxes are already satisfied by construction if using box-swap operator
```

**Temperature schedule**: start high (T=1.0), cool slowly (cooling_rate=0.9995), stop when T < 0.001 or no improvement for N iterations.

**Reheating (optional)**: if stuck in a local minimum for too long, reheat T to escape. This is mentioned in the assignment as an optional enhancement.

#### 4b. Genetic Algorithm (GA)

GA maintains a **population** of complete solutions (chromosomes) and evolves them toward the optimum using selection, crossover, and mutation operators.

**Chromosome representation**: a list of 81 integers (the flattened 9×9 grid). Pre-filled cells are immutable.

**Algorithm**:
```
1. Initialize population of N chromosomes (each is a valid-ish complete board)
2. Evaluate fitness of each chromosome: fitness = -cost (maximize = minimize violations)
3. While not solved and generation < max_gen:
    a. Select parents (tournament selection or roulette wheel)
    b. Apply crossover: combine two parents to produce offspring
    c. Apply mutation: randomly swap cells within a box
    d. Replace worst individuals with offspring
    e. Evaluate fitness
4. Return best chromosome found
```

**Crossover**: uniform crossover works here — for each cell, randomly take from parent 1 or parent 2. Ensure pre-filled cells remain fixed. Box-preserving crossover (copy entire boxes from one parent) is often more effective.

**Mutation**: same as SA operator — swap two non-given cells within a box.

**Selection pressure**: tournament selection of size 3–5 is standard. Too high = premature convergence. Too low = slow.

**Fitness function**: same as SA cost function, negated. A chromosome with 0 violations is a perfect solution.

---

## Implementation Plan — Ground Zero

This is the order you should implement things. Do not skip steps.

### Phase 0 — Environment Setup

**SWI-Prolog**:
```bash
# macOS
brew install swi-prolog

# Ubuntu/Debian
sudo apt install swi-prolog

# Verify
swipl --version
```

**Python**:
```bash
python3 --version  # needs 3.9+
pip install numpy  # for board operations
```

**VSCode Extensions**:
- `VSC-Prolog` (id: `arthurwang.vsc-prolog`) — syntax highlighting, linting, run Prolog from editor
- `Python` (ms-python.python)

**VSCode settings** — add to `.vscode/settings.json`:
```json
{
  "prolog.executablePath": "/usr/local/bin/swipl",
  "prolog.dialectPath": "swi"
}
```

### Phase 1 — Board Representation (Prolog)

Decide your representation first. Recommended: a flat list of 81 elements, row-major order. Cell at row R (1-indexed), column C is at index `(R-1)*9 + C`. Value `0` means empty.

```prolog
% Example: access cell at (Row, Col)
cell(Board, Row, Col, Value) :-
    Index is (Row - 1) * 9 + (Col - 1),
    nth0(Index, Board, Value).

% Get the 3x3 box index (0-8)
box_index(Row, Col, BoxIdx) :-
    BoxRow is (Row - 1) // 3,
    BoxCol is (Col - 1) // 3,
    BoxIdx is BoxRow * 3 + BoxCol.
```

Write and test these predicates in isolation before building anything on top.

### Phase 2 — Constraint Checking (Prolog)

```prolog
% All values in a list are unique (ignoring zeros)
all_different([]).
all_different([H|T]) :-
    \+ member(H, T),
    all_different(T).

% Valid row: no duplicate non-zero values
valid_row(Board, Row) :- ...

% Valid column
valid_col(Board, Col) :- ...

% Valid box
valid_box(Board, BoxIdx) :- ...

% Full validity check
valid(Board) :-
    forall(between(1,9,R), valid_row(Board,R)),
    forall(between(1,9,C), valid_col(Board,C)),
    forall(between(0,8,B), valid_box(Board,B)).
```

### Phase 3 — DFID Solver (Prolog)

```prolog
solve_dfid(Board, Solution) :-
    empty_cells(Board, Empties),
    length(Empties, N),
    between(N, 81, Depth),
    dfid(Board, Depth, Solution), !.

dfid(Board, _, Board) :- solved(Board).
dfid(Board, D, Solution) :-
    D > 0,
    next_empty(Board, Row, Col),
    between(1, 9, Value),
    valid_placement(Board, Row, Col, Value),
    place(Board, Row, Col, Value, NewBoard),
    D1 is D - 1,
    dfid(NewBoard, D1, Solution).
```

The key optimization: use **MRV (Minimum Remaining Values)** in `next_empty/3` — pick the empty cell with the fewest valid candidates first. This massively prunes the tree.

### Phase 4 — A* Solver (Prolog)

You need an open list (priority queue by f-value) and a closed list. Use SWI-Prolog's `library(heaps)`:

```prolog
:- use_module(library(heaps)).

solve_astar(Board, Solution) :-
    h(Board, H),
    singleton_heap(Open, H-state(Board, 0)),
    astar(Open, [], Solution).

astar(Open, _, Solution) :-
    get_from_heap(Open, _F, state(Board, _G), _Rest),
    solved(Board), !,
    Solution = Board.

astar(Open, Closed, Solution) :-
    get_from_heap(Open, _F, state(Board, G), Rest),
    \+ member(Board, Closed),
    expand(Board, G, Rest, NewOpen),
    astar(NewOpen, [Board|Closed], Solution).
```

Your heuristic: number of empty cells. Or better: sum over all empty cells of `(number_of_candidates(cell) - 1)` — still admissible, more informative.

### Phase 5 — Killer Sudoku Extension (Prolog)

Add cage data structure. Represent cages as a list of `cage(Sum, Cells)` terms where `Cells` is a list of `(Row, Col)` pairs.

```prolog
% Example cage: cells (1,1),(1,2),(2,1) must sum to 15
cage(15, [(1,1),(1,2),(2,1)]).

% Validate all cages
valid_cages(Board, Cages) :-
    maplist(valid_cage(Board), Cages).

valid_cage(Board, cage(Sum, Cells)) :-
    maplist(cell_value(Board), Cells, Values),
    % For complete boards: check sum and uniqueness
    sum_list(Values, Sum),
    all_different(Values).
```

For partial boards during search, add a **partial cage constraint**: if all cage cells are filled, check sum and uniqueness. If partially filled, check that remaining capacity can still reach the sum.

### Phase 6 — SA Solver (Python)

```
src/
  python/
    sa_solver.py
    ga_solver.py
    board.py        # Board representation and helpers
    puzzles.py      # Hardcoded test puzzles
```

The `board.py` module handles loading, displaying, and validating a board. The solvers import from it. Keep the interface clean.

### Phase 7 — GA Solver (Python)

Implement after SA is working. The fitness evaluation is the same cost function — share it.

### Phase 8 — Testing

Test every solver on at least:
- An easy puzzle (many given cells, ~35+)
- A medium puzzle (~30 given cells)
- A hard puzzle (~25 given cells)
- An expert/evil puzzle (~20–22 given cells)
- A Killer Sudoku puzzle

Record: time to solve, nodes expanded (for search), convergence generations (for GA), cost curve (for SA). You need these for the report.

---

## Project Structure

```
ai-killer-sudoku/
├── src/
│   ├── prolog/
│   │   ├── sudoku.pl          # Board representation + constraints
│   │   ├── dfid.pl            # DFID solver
│   │   ├── astar.pl           # A* solver
│   │   └── killer_sudoku.pl   # Killer Sudoku extension
│   └── python/
│       ├── board.py           # Shared board utilities
│       ├── puzzles.py         # Hardcoded test puzzles
│       ├── sa_solver.py       # Simulated Annealing
│       └── ga_solver.py       # Genetic Algorithm
├── data/
│   ├── input/                 # Test puzzle files
│   └── output/                # Solver output logs
├── scripts/
│   └── benchmark.sh           # Run all solvers on all puzzles
├── docs/
│   └── 2Project-AI-2526Summer.pdf
└── README.md
```

---

## Running the Solvers

### Prolog — DFID
```bash
swipl -s src/prolog/dfid.pl -g "solve_dfid(puzzle_easy, S), print_board(S), halt"
```

### Prolog — A*
```bash
swipl -s src/prolog/astar.pl -g "solve_astar(puzzle_expert, S), print_board(S), halt"
```

### Python — Simulated Annealing
```bash
python3 src/python/sa_solver.py --puzzle expert
```

### Python — Genetic Algorithm
```bash
python3 src/python/ga_solver.py --puzzle expert --pop 200 --generations 10000
```

---

## Grading Requirements — What You Must Deliver

Per the assignment spec:

1. **Report** (mandatory): concise, explains main Prolog predicates and data structures, justifies every design decision. Includes experimental results: solve time per algorithm per puzzle, comparison table. Includes group member names and course info.

2. **Prolog code**: DFID solver + A* solver, both working on standard Sudoku and Killer Sudoku.

3. **Optimization code**: SA solver + GA solver in Python (or any language). Both must work on standard Sudoku. Killer Sudoku extension is expected.

4. **Test puzzles**: at least one easy, medium, hard, and expert puzzle. All must be well-formed (unique solution).

5. **Submission**: upload everything to Moodle by 19 May 2026 at 23:59. Late submissions are not accepted.

---

## Algorithm Comparison — What to Expect

| Algorithm | Complete | Optimal | Memory | Speed on Hard Puzzles |
|---|---|---|---|---|
| DFID | Yes (with backtracking) | No (finds first) | O(depth) | Slow without MRV |
| A* | Yes | Yes (admissible h) | O(open list) | Better than DFID with good h |
| SA | No | No | O(1) | Fast, probabilistic |
| GA | No | No | O(pop × board) | Variable, depends on tuning |

SA and GA will outperform search algorithms on the hardest Sudoku instances. DFID and A* are guaranteed to find solutions but may time out on expert puzzles without aggressive pruning. This is by design — it is the point of the assignment.

---

## Critical Notes

- **DFID in Prolog must use backtracking natively.** Do not simulate it. Prolog's execution model is the search.
- **Your A* heuristic must be admissible.** If it is not, A* is not guaranteed optimal and you lose points. Prove admissibility in your report.
- **SA and GA are stochastic.** Run each multiple times and report averages. A single run result is meaningless.
- **Killer Sudoku cage constraints are pruning opportunities.** An incomplete cage that cannot possibly reach its target sum should be pruned immediately. Do not wait for full assignment to detect this.
- **State representation is a design decision.** You must justify it in the report. Changing it mid-project is painful.
- **I/O is text-based.** No GUI required. A clean text print of the 9×9 grid is sufficient.

---

## References

- Assignment PDF: `docs/2Project-AI-2526Summer.pdf`
- Sudoku puzzle database: `https://github.com/t-dillon/tdoku/blob/master/data.zip`
- Sudoku Wikipedia: `https://en.wikipedia.org/wiki/Sudoku`
- SWI-Prolog heaps library: `https://www.swi-prolog.org/pldoc/man?section=heaps`
