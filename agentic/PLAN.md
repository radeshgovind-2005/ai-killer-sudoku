# Implementation Plan — AI Killer Sudoku

**Project deadline**: 19 May 2026 at 23:59
**Plan created**: 2026-05-14
**Last updated**: 2026-05-14 (all phases implemented)
**Scope**: Everything except the written report

---

## Current State Snapshot

| File | State |
|---|---|
| `src/prolog/sudoku.pl` | **DONE** — full constraint layer: `all_different`, `valid_row/col/box`, `valid`, `valid_placement`, `candidates`, `empty_cells`, `next_empty` (MRV), `solved`, `place` |
| `src/prolog/dfid.pl` | **DONE** — DFID solver with MRV, node counter, wall-clock timing, `solve_file/2` CLI entry point. Untracked in git — needs commit. |
| `src/python/board.py` | **DONE** — full board utilities mirroring Prolog module |
| `src/python/puzzles.py` | Placeholder — one path reference only |
| `data/input/classic_easy_01.txt` | One easy puzzle. Missing: medium, hard, expert, killer |
| `src/prolog/astar.pl` | **DONE** — heap-based A*, h=empty cells, MRV expansion, closed list, stats |
| `src/prolog/killer_sudoku.pl` | **DONE** — cage layer, partial pruning, DFID+A* killer variants, easy_01 puzzle |
| `src/python/sa_solver.py` | **DONE** — box-init state, box-swap operator, stagnation restart, fast cost |
| `src/python/ga_solver.py` | **DONE** — box-preserving crossover, multi-swap mutation, tournament, elitism |
| `scripts/benchmark.sh` | **DONE** — runs all 4 solvers on all puzzles, logs to data/output/ |

---

## Schedule — 5 Days to Deadline

| Day | Date | Phases | Deliverables |
|---|---|---|---|
| 1 | May 14 (today) | Phase 7 + Phase 3 start | All 5 puzzle files added; `astar.pl` skeleton + heap loop |
| 2 | May 15 | Phase 3 complete | `astar.pl` working and tested on easy puzzle |
| 3 | May 16 | Phase 4 | `killer_sudoku.pl` with cage constraints + killer solvers |
| 4 | May 17 | Phase 5 + Phase 6 | `sa_solver.py` + `ga_solver.py` both working |
| 5 | May 18 | Phase 8 | `benchmark.sh` run, all results in `data/output/` |
| — | May 19 | Report + submission | Report written, everything uploaded to Moodle by 23:59 |

**Rationale**: Puzzles first (Day 1) because every solver needs test inputs. A* before Killer Sudoku because Killer depends on it. SA before GA because GA reuses SA's cost function. Benchmark last because it requires all solvers and all puzzles.

---

## Phase 1 — Prolog Constraint Layer ✅ COMPLETE

**File**: `src/prolog/sudoku.pl`

### Tasks
- [x] `all_different(List)` — filters zeros, msort + duplicate check
- [x] `valid_row(Board, Row)`
- [x] `valid_col(Board, Col)`
- [x] `valid_box(Board, BoxIndex)`
- [x] `valid(Board)` — forall over rows, cols, boxes
- [x] `valid_placement(Board, Row, Col, Value)` — row/col/box membership check
- [x] `empty_cells(Board, Cells)` — findall over (R,C) with value 0
- [x] `next_empty(Board, Row, Col)` — MRV: picks cell with fewest candidates
- [x] `candidates(Board, Row, Col, Candidates)` — findall valid values 1-9
- [x] `solved(Board)` — `\+ member(0, Board)`
- [x] `place(Board, Row, Col, Value, NewBoard)` — thin alias over set_cell

---

## Phase 2 — DFID Solver ✅ COMPLETE

**File**: `src/prolog/dfid.pl`

### Tasks
- [x] `:- use_module(sudoku)` — imports constraint layer
- [x] `solve_dfid(Board, Solution)` — entry point with node counter + wall-clock timer
- [x] `dfid(Board, DepthLimit, Solution)` — bounded DFS using Prolog backtracking
- [x] MRV via `next_empty` — key pruning optimization
- [x] Stats output: nodes expanded + elapsed seconds
- [x] `solve_file(Path, Solution)` — CLI convenience predicate
- [x] **Pending**: commit `dfid.pl` to git (currently untracked)

---

## Phase 3 — A* Solver (Prolog)

**File**: `src/prolog/astar.pl` (create)

### Design
- Uses `library(heaps)` for the open list (min-heap on f value)
- Closed list as a plain Prolog list (or asserta for large puzzles)
- `g(n)` = number of cells placed (depth)
- `h(n)` = number of empty cells (admissible) OR sum of `(candidates(cell) - 1)` over all empty cells (more informed, still admissible)
- Use the stronger heuristic — it dominates the simpler one

### Tasks
- [ ] `:- use_module(library(heaps))`
- [ ] `h(Board, H)` — heuristic: sum of (candidate_count - 1) per empty cell
- [ ] `f_value(Board, G, F)` — compute f = g + h
- [ ] `expand(Board, G, OpenIn, OpenOut)` — generate successors, compute f, insert into heap
- [ ] `solve_astar(Board, Solution)` — entry point, initialise heap and closed list
- [ ] `astar(Open, Closed, Solution)` — main loop
- [ ] Closed list check to avoid re-expanding visited states
- [ ] `print_solution/1` — print board + stats (nodes expanded, time)
- [ ] Test on `classic_easy_01.txt`

### Key predicates
```prolog
:- use_module(library(heaps)).

solve_astar(Board, Solution) :-
    h(Board, H),
    singleton_heap(Open, H-state(Board, 0)),
    astar(Open, [], Solution).

astar(Open, _, Solution) :-
    get_from_heap(Open, _F, state(Board, _G), _),
    solved(Board), !,
    Solution = Board.

astar(Open, Closed, Solution) :-
    get_from_heap(Open, _F, state(Board, G), Rest),
    \+ member(Board, Closed),
    expand(Board, G, Rest, NewOpen),
    astar(NewOpen, [Board|Closed], Solution).
```

---

## Phase 4 — Killer Sudoku Extension (Prolog)

**File**: `src/prolog/killer_sudoku.pl` (create)

### Design
- Cage term: `cage(TargetSum, [(R1,C1),(R2,C2),...])`
- Add cage constraints on top of standard Sudoku constraints
- Partial cage check during search: if all cage cells filled, verify sum + uniqueness; if partially filled, verify remaining capacity can still reach target

### Tasks
- [ ] `:- use_module(src/prolog/sudoku)`
- [ ] `valid_cage(Board, Cage)` — full check (all cells filled): sum matches + all_different
- [ ] `partial_cage_check(Board, Cage)` — pruning check for incomplete cages
  - Sum of filled cells must not exceed target
  - Remaining empty cells must be able to contribute enough to reach target (lower bound: remaining * 1, upper bound: remaining * 9, minus already used values)
- [ ] `valid_cages(Board, Cages)` — maplist over all cages
- [ ] `solve_dfid_killer(Board, Cages, Solution)` — DFID extended with cage pruning
- [ ] `solve_astar_killer(Board, Cages, Solution)` — A* extended with cage pruning
- [ ] Define at least one killer puzzle in the file for testing
- [ ] Test: a known killer puzzle solves to the correct answer

### Cage data format
```prolog
% Puzzle definition
killer_puzzle(example, Board, Cages) :-
    board_from_string("...", Board),
    Cages = [
        cage(15, [(1,1),(1,2),(2,1)]),
        cage(3,  [(1,3),(2,3)]),
        ...
    ].
```

---

## Phase 5 — Simulated Annealing (Python)

**File**: `src/python/sa_solver.py` (create)

### Design
- State: complete 9x9 grid, given cells fixed; each 3x3 box is filled with 1-9 (boxes satisfied by construction)
- Operator: swap two non-given cells within the same 3x3 box
- Cost: row violations + column violations (boxes always valid by construction)
- Schedule: T_initial=1.0, cooling_rate=0.9995, T_min=0.001
- Restart on stagnation (if no improvement for K iterations, reinitialise)

### Tasks
- [ ] `initialize(board: Board, givens: set) -> Board` — fill each box with remaining 1-9 values, respecting givens
- [ ] `cost(board: Board) -> int` — count row + column duplicates
- [ ] `neighbor(board: Board, givens: set) -> Board` — pick random box, swap two non-given cells
- [ ] `simulated_annealing(board, givens, T_init, cooling, T_min, max_stagnation)` — main loop
- [ ] Return best board found + final cost + iterations run
- [ ] `main()` — CLI with `--puzzle` argument, loads from `data/input/`, prints result + stats
- [ ] Run on all 4 puzzle difficulties, record results in `data/output/sa_results.txt`

### Cost function
```python
def cost(board: Board) -> int:
    violations = 0
    for i in range(9):
        r = row(board, i + 1)
        c = column(board, i + 1)
        violations += 9 - len(set(r))
        violations += 9 - len(set(c))
    return violations
    # Boxes: always 0 by construction (box-swap operator preserves box uniqueness)
```

---

## Phase 6 — Genetic Algorithm (Python)

**File**: `src/python/ga_solver.py` (create)

### Design
- Chromosome: same representation as SA (box-initialized complete board)
- Fitness: `-cost(board)` (maximize = minimize violations)
- Selection: tournament selection (size 3)
- Crossover: box-preserving — copy entire 3x3 boxes from one parent or the other
- Mutation: same box-swap operator as SA
- Population size: 200; max generations: 10000; elitism: keep top 2

### Tasks
- [ ] `random_chromosome(board, givens) -> Board` — same as SA initialise
- [ ] `fitness(board) -> int` — returns `-cost(board)`
- [ ] `tournament_select(population, fitnesses, k=3) -> Board`
- [ ] `crossover(parent1, parent2, givens) -> Board` — box-preserving crossover
- [ ] `mutate(board, givens, mutation_rate=0.1) -> Board` — box-swap
- [ ] `genetic_algorithm(board, givens, pop_size, max_gen)` — main loop with elitism
- [ ] Return best board + generation found + final fitness
- [ ] `main()` — CLI with `--puzzle`, `--pop`, `--generations` args
- [ ] Run on all 4 puzzle difficulties, record results in `data/output/ga_results.txt`

---

## Phase 7 — Test Puzzles  ← START HERE (Day 1)

**Directory**: `data/input/`

Puzzles must exist before any solver can be tested. Add them first.

### Tasks
- [x] `classic_easy_01.txt` — already exists (35+ givens)
- [ ] `classic_medium_01.txt` — ~30 givens
- [ ] `classic_hard_01.txt` — ~25 givens
- [ ] `classic_expert_01.txt` — ~22 givens (AI Escargot or equivalent)
- [ ] `killer_easy_01.txt` — format: first line is board (dots/digits), then one `cage(Sum,[(R,C),...])` term per line
- [ ] Verify all classic puzzles have unique solutions before using them

### Classic puzzle format (shared with Prolog load_board)
```
53..7....
6..195...
.98....6.
8...6...3
4..8.3..1
7...2...6
.6....28.
...419..5
....8..79
```

### Killer puzzle format (proposed)
```
% Board: all zeros (fully empty for pure killer, or partially filled)
000000000
...
% Cages
cage(3,  [(1,1),(1,2)]).
cage(15, [(1,3),(1,4),(1,5)]).
...
```

### Puzzle sources
- Classic: https://github.com/t-dillon/tdoku (verified unique-solution puzzles)
- Killer: https://www.dailykiller.com or manually crafted

---

## Phase 8 — Benchmark Script

**File**: `scripts/benchmark.sh` (create)

### Tasks
- [ ] Run DFID on all classic puzzles, capture time + output
- [ ] Run A* on all classic puzzles, capture time + output
- [ ] Run SA on all classic puzzles (5 runs each), capture time + cost curve
- [ ] Run GA on all classic puzzles (5 runs each), capture generations + cost
- [ ] Run DFID + A* on killer puzzle
- [ ] Write all results to `data/output/benchmark_results.txt`
- [ ] Print a summary comparison table to stdout

---

## Dependency Order

```
Phase 1 (constraints) ✅
    └── Phase 2 (DFID) ✅
    └── Phase 3 (A*)          ← Day 1–2
    └── Phase 4 (Killer)      ← Day 3, depends on Phase 2 + Phase 3
Phase 7 (puzzles)             ← Day 1 (unblocked, do first)
Phase 5 (SA)                  ← Day 4, independent of Prolog
Phase 6 (GA)                  ← Day 4, depends on Phase 5 cost function
Phase 8 (benchmark)           ← Day 5, depends on all solvers + all puzzles
Report                        ← Day 6 (May 19), depends on benchmark results
```
