# Run & Test Guide — AI Killer Sudoku

**Course**: Inteligência Artificial — ISEL, 2025/2026
**Deadline**: 19 May 2026 at 23:59 (Moodle)

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Project Layout](#2-project-layout)
3. [Puzzle Files](#3-puzzle-files)
4. [Running the Prolog Solvers](#4-running-the-prolog-solvers)
   - [4a. DFID](#4a-dfid-depth-first-iterative-deepening)
   - [4b. A*](#4b-a-best-first-informed-search)
   - [4c. Killer Sudoku (DFID + A*)](#4c-killer-sudoku-dfid--a)
5. [Running the Python Solvers](#5-running-the-python-solvers)
   - [5a. Simulated Annealing](#5a-simulated-annealing-sa)
   - [5b. Genetic Algorithm](#5b-genetic-algorithm-ga)
6. [Running All Benchmarks](#6-running-all-benchmarks)
7. [Testing Checklist](#7-testing-checklist)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Prerequisites

### SWI-Prolog

```bash
# macOS
brew install swi-prolog

# Ubuntu/Debian
sudo apt install swi-prolog

# Verify (need 8.x or later)
swipl --version
```

### Python

No third-party packages are required. The solvers use only the Python standard library.

```bash
# Need Python 3.9+
python3 --version
```

---

## 2. Project Layout

```
ai-killer-sudoku/
├── src/
│   ├── prolog/
│   │   ├── sudoku.pl          # Board + constraints (shared module)
│   │   ├── dfid.pl            # DFID solver
│   │   ├── astar.pl           # A* solver
│   │   └── killer_sudoku.pl   # Killer Sudoku extension (DFID + A*)
│   └── python/
│       ├── board.py           # Shared board utilities
│       ├── puzzles.py         # Puzzle file paths
│       ├── sa_solver.py       # Simulated Annealing
│       └── ga_solver.py       # Genetic Algorithm
├── data/
│   ├── input/                 # Test puzzles (.txt)
│   └── output/                # Solver result logs (auto-created)
├── scripts/
│   └── benchmark.sh           # Full benchmark runner
├── docs/
│   └── 2Project-AI-2526Summer.pdf
└── README.md
```

All commands below assume you are in the **project root** (`ai-killer-sudoku/`).

---

## 3. Puzzle Files

| File | Difficulty | Givens | Notes |
|------|-----------|--------|-------|
| `data/input/classic_easy_01.txt` | Easy | 35 | Wikipedia Sudoku |
| `data/input/classic_medium_01.txt` | Medium | ~30 | Standard puzzle |
| `data/input/classic_hard_01.txt` | Hard | ~25 | Requires MRV pruning |
| `data/input/classic_expert_01.txt` | Expert | ~20 | Very few givens |
| `data/input/killer_easy_01.txt` | Killer Easy | 0 | Cage-based puzzle |

**Classic format** (9 lines × 9 characters, `0` = empty):
```
530070000
600195000
098000060
...
```

**Killer format** (board lines followed by cage definitions):
```
000000000
000000000
...
cage(12,[(1,1),(1,2),(1,3)]).
cage(21,[(1,4),(1,5),(1,6)]).
...
```

---

## 4. Running the Prolog Solvers

### 4a. DFID (Depth-First Iterative Deepening)

**Module**: `src/prolog/dfid.pl`
**Algorithm**: Uninformed DFS with MRV (Minimum Remaining Values) heuristic.

```bash
# Easy puzzle
swipl -s src/prolog/dfid.pl \
  -g "solve_file('data/input/classic_easy_01.txt', _), halt"

# Medium puzzle
swipl -s src/prolog/dfid.pl \
  -g "solve_file('data/input/classic_medium_01.txt', _), halt"

# Hard puzzle
swipl -s src/prolog/dfid.pl \
  -g "solve_file('data/input/classic_hard_01.txt', _), halt"

# Expert puzzle (may be slow — allow a few minutes)
swipl -s src/prolog/dfid.pl \
  -g "solve_file('data/input/classic_expert_01.txt', _), halt"
```

**Expected output:**
```
Nodes expanded : 4521
Elapsed        : 0.023 s

Solution:
5 3 4 | 6 7 8 | 9 1 2
6 7 2 | 1 9 5 | 3 4 8
...
```

**Interactive Prolog session** (useful for debugging):
```bash
swipl -s src/prolog/dfid.pl
# Then at the ?- prompt:
?- solve_file('data/input/classic_easy_01.txt', S).
?- halt.
```

---

### 4b. A* (Best-First Informed Search)

**Module**: `src/prolog/astar.pl`
**Algorithm**: Best-first search with heuristic `h(n)` = number of empty cells (admissible).

```bash
# Easy puzzle
swipl -s src/prolog/astar.pl \
  -g "solve_file('data/input/classic_easy_01.txt', _), halt"

# Medium puzzle
swipl -s src/prolog/astar.pl \
  -g "solve_file('data/input/classic_medium_01.txt', _), halt"

# Hard puzzle
swipl -s src/prolog/astar.pl \
  -g "solve_file('data/input/classic_hard_01.txt', _), halt"

# Expert puzzle (memory-intensive — A* closed list grows large)
swipl -s src/prolog/astar.pl \
  -g "solve_file('data/input/classic_expert_01.txt', _), halt"
```

**Expected output:** Same format as DFID — nodes expanded and elapsed time followed by the solution grid.

> **Note**: A* requires more memory than DFID due to the open/closed lists. On expert puzzles it may exhaust memory before finding a solution; DFID is preferred for very hard instances.

---

### 4c. Killer Sudoku (DFID + A*)

**Module**: `src/prolog/killer_sudoku.pl`
**Algorithm**: Runs both DFID and A* with cage constraint checking.

The killer puzzle (`easy_01`) is hardcoded in the module (board + 27 cage definitions).

```bash
# Solve the hardcoded killer puzzle with both DFID and A*
swipl -s src/prolog/killer_sudoku.pl \
  -g "solve_killer_file(easy_01, _), halt"
```

**Expected output:**
```
Killer puzzle: easy_01

Solving with DFID...
Nodes expanded : ...
Elapsed        : ... s
Solution (DFID):
...

Solving with A*...
Nodes expanded : ...
Elapsed        : ... s
Solution (A*):
...
```

---

## 5. Running the Python Solvers

Both solvers are invoked via `python3` from the project root. All puzzle paths are resolved automatically relative to the script location — you do not need to `cd` into `src/python/`.

**Puzzle choices** for `--puzzle`: `easy`, `medium`, `hard`, `expert`, `killer`

---

### 5a. Simulated Annealing (SA)

**Script**: `src/python/sa_solver.py`

**CLI arguments:**
| Flag | Default | Description |
|------|---------|-------------|
| `--puzzle` | `easy` | Puzzle to solve (`easy`, `medium`, `hard`, `expert`, `killer`) |
| `--runs` | `1` | Number of independent runs |
| `--seed` | (none) | Random seed for reproducibility |

```bash
# Single run — easy
python3 src/python/sa_solver.py --puzzle easy

# Multiple runs — stochastic, always use --runs for meaningful results
python3 src/python/sa_solver.py --puzzle medium --runs 5

# Hard puzzle, 3 runs
python3 src/python/sa_solver.py --puzzle hard --runs 3

# Expert puzzle, 5 runs
python3 src/python/sa_solver.py --puzzle expert --runs 5

# Killer Sudoku
python3 src/python/sa_solver.py --puzzle killer --runs 3

# Reproducible run (fixed seed)
python3 src/python/sa_solver.py --puzzle expert --runs 5 --seed 42
```

**Expected output:**
```
Puzzle (easy):
5 3 . | . 7 . | . . .
6 . . | 1 9 5 | . . .
...

Run 1/3: SOLVED | iters=75,432 | time=0.234s
Run 2/3: SOLVED | iters=82,156 | time=0.267s
Run 3/3: UNSOLVED (cost=2) | iters=300,000 | time=1.234s

Best solution found:
5 3 4 | 6 7 8 | 9 1 2
...
```

> SA is stochastic. A single run may fail; run at least 3–5 times and report averages. Results are appended to `data/output/sa_results.txt`.

---

### 5b. Genetic Algorithm (GA)

**Script**: `src/python/ga_solver.py`

**CLI arguments:**
| Flag | Default | Description |
|------|---------|-------------|
| `--puzzle` | `easy` | Puzzle to solve (`easy`, `medium`, `hard`, `expert`, `killer`) |
| `--pop` | `200` | Population size |
| `--generations` | `10000` | Maximum generations |
| `--runs` | `1` | Number of independent runs |
| `--seed` | (none) | Random seed for reproducibility |

```bash
# Single run — easy
python3 src/python/ga_solver.py --puzzle easy

# Medium, 3 runs
python3 src/python/ga_solver.py --puzzle medium --runs 3

# Hard, larger population
python3 src/python/ga_solver.py --puzzle hard --pop 300 --generations 10000 --runs 3

# Expert (may not always solve — stochastic)
python3 src/python/ga_solver.py --puzzle expert --pop 300 --generations 10000 --runs 5

# Killer Sudoku
python3 src/python/ga_solver.py --puzzle killer --pop 200 --generations 10000 --runs 3

# Reproducible run
python3 src/python/ga_solver.py --puzzle easy --runs 3 --seed 42
```

**Expected output:**
```
Puzzle (easy):
5 3 . | . 7 . | . . .
...

Run 1/3: SOLVED | gen=234 | time=0.456s
Run 2/3: SOLVED | gen=187 | time=0.389s
Run 3/3: UNSOLVED (cost=1) | gen=10000 | time=2.123s

Best solution found:
5 3 4 | 6 7 8 | 9 1 2
...
```

> GA is stochastic. Results are appended to `data/output/ga_results.txt`.

---

## 6. Running All Benchmarks

The benchmark script runs every solver on every puzzle and writes a combined log.

```bash
bash scripts/benchmark.sh
```

**What it runs (in order):**
1. DFID on `easy`, `medium`, `hard`, `expert`
2. A* on `easy`, `medium`, `hard`, `expert`
3. Killer Sudoku DFID + A* on `easy_01`
4. SA on `easy`, `medium`, `hard`, `expert` (3 runs each)
5. GA on `easy`, `medium`, `hard`, `expert` — `--pop 200 --generations 10000` (3 runs each)
6. SA on `killer` (3 runs)
7. GA on `killer` (3 runs)

**Configuration** (edit at top of `benchmark.sh`):
```bash
PYTHON_RUNS=3        # runs per stochastic solver
PROLOG_TIMEOUT=120   # seconds per Prolog call before timeout
```

**Output files:**
- `data/output/benchmark_results.txt` — full log of all runs
- stdout — summary header + per-solver section

> The benchmark truncates `benchmark_results.txt` on each run. Move or copy the file if you want to keep previous results.

---

## 7. Testing Checklist

Use this to verify each solver is working correctly before submission.

### Prolog — verify each solver finds the correct solution

```bash
# DFID — should solve easy in < 0.5s, medium in < 5s
swipl -s src/prolog/dfid.pl \
  -g "solve_file('data/input/classic_easy_01.txt', _), halt"

swipl -s src/prolog/dfid.pl \
  -g "solve_file('data/input/classic_medium_01.txt', _), halt"

# A* — same puzzles
swipl -s src/prolog/astar.pl \
  -g "solve_file('data/input/classic_easy_01.txt', _), halt"

swipl -s src/prolog/astar.pl \
  -g "solve_file('data/input/classic_medium_01.txt', _), halt"

# Killer Sudoku — both algorithms in one call
swipl -s src/prolog/killer_sudoku.pl \
  -g "solve_killer_file(easy_01, _), halt"
```

### Python — verify both solvers run and output a solution

```bash
# SA — quick smoke test (easy, 1 run)
python3 src/python/sa_solver.py --puzzle easy

# GA — quick smoke test (easy, 1 run)
python3 src/python/ga_solver.py --puzzle easy

# SA — killer
python3 src/python/sa_solver.py --puzzle killer

# GA — killer
python3 src/python/ga_solver.py --puzzle killer
```

### Cross-solver validation

Solutions from all four algorithms on the same puzzle should be identical (there is only one valid solution per well-formed puzzle). Compare outputs visually or redirect to files:

```bash
swipl -s src/prolog/dfid.pl \
  -g "solve_file('data/input/classic_easy_01.txt', _), halt" > /tmp/dfid_easy.txt 2>&1

python3 src/python/sa_solver.py --puzzle easy --seed 0 > /tmp/sa_easy.txt

# Check both files show the same 9×9 grid in the solution section
```

---

## 8. Troubleshooting

**`swipl: command not found`**
Install SWI-Prolog: `brew install swi-prolog` (macOS) or `sudo apt install swi-prolog` (Linux).

**`ERROR: Module sudoku not found`**
Run from the project root. The `dfid.pl` and `astar.pl` modules load `sudoku` as a relative path; they must be invoked from `ai-killer-sudoku/`.

**`ModuleNotFoundError: No module named 'board'`**
Run via `python3 src/python/sa_solver.py` (not `cd src/python && python3 sa_solver.py`). When invoked as `python3 src/python/sa_solver.py`, Python adds `src/python/` to `sys.path` automatically.

**`ERROR: library(heaps): not found`**
You have an older SWI-Prolog. Update to 8.x+: `brew upgrade swi-prolog` or `sudo apt upgrade swi-prolog`.

**Prolog solver times out on expert puzzle**
This is expected — DFID and A* without arc consistency can be very slow on expert-level Sudoku. The benchmark script allows 120 seconds and marks timeouts as such. SA and GA are the intended solvers for hard instances.

**SA/GA never solve the puzzle**
Run more times with `--runs 5` or higher. These are stochastic — occasional failures are normal. The report should present success rate and average time across runs, not a single run result.

**Benchmark script fails with `kill: illegal signal specification`**
On macOS, the `timeout` command from GNU coreutils is not available. The script implements its own timeout using `kill -9` in a background watcher process — this is already handled. If you see this error, check your shell is `bash` (not `sh`): `bash scripts/benchmark.sh`.
