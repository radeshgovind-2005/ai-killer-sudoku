# Heuristics & Evaluation Functions

Cross-algorithm reference for every heuristic and scoring function used in this project.

---

## Overview

```mermaid
graph TD
    subgraph "Search Algorithms"
        DFID["DFID\nNo heuristic\n(uninformed)"]
        ASTAR["A*\nAdmissible h(n)\n(informed)"]
    end

    subgraph "Optimisation Algorithms"
        SA["Simulated Annealing\nEnergy = violations(board)"]
        GA["Genetic Algorithm\nFitness = max − violations(board)"]
    end

    H1["h₁: empty cell count"] --> ASTAR
    H2["h₂: MRV sum"] --> ASTAR
    H3["h₃: degree heuristic"] --> ASTAR
    VIOL["violations(board)\n= row + col + box + cage errors"] --> SA
    VIOL --> GA
```

---

## A\* Heuristics

### h₁ — Empty Cell Count

```
h₁(n) = |{ cells (r,c) : board[r][c] = 0 }|
```

| Property | Status |
|----------|--------|
| Admissible | Yes — always ≤ true cost |
| Consistent | Yes |
| Informative | Low — ignores constraints |
| Computation | O(1) |

### h₂ — MRV (Minimum Remaining Values)

```
h₂(n) = Σ  max(0,  domain(c) − 1)
        c ∈ empty_cells

domain(c) = { d ∈ 1..9 : d not in row(c) ∪ col(c) ∪ box(c) }
```

```mermaid
graph TD
    subgraph "MRV Example — which cell to expand?"
        CA["Cell A\nrow conflicts: {3,5}\ncol conflicts: {1,7,9}\nbox conflicts: {2}\ndomain = {4,6,8}  → size 3"]
        CB["Cell B\nrow conflicts: {1,2,3,4,5,6,7,8}\ndomain = {9}  → size 1  ← MRV picks this"]
        CC["Cell C\ndomain = {2,4,6,7,9}  → size 5"]
    end

    CB -->|"forced — assign 9"| NEXT["No branching needed\nh₂ contribution = 0"]
    style CB fill:#90EE90,stroke:#2d6a2d,color:#000
```

| Property | Status |
|----------|--------|
| Admissible | Yes |
| Consistent | Yes |
| Informative | High — exploits constraint propagation |
| Computation | O(empty_cells × 27) |

### h₃ — Degree Heuristic (tie-breaker)

Used when two cells have the same MRV score:

```
degree(c) = |{ c' ∈ empty_cells : c' shares row, col, or box with c }|
```

Pick the cell with the **highest degree** — it will prune the most branches.

---

## Violations Function (SA & GA)

```mermaid
flowchart TD
    BOARD["Board state\n(complete assignment)"] --> ROWS["Row violations\nΣ 9 − |unique(row_r)|  for r=0..8"]
    BOARD --> COLS["Col violations\nΣ 9 − |unique(col_c)|  for c=0..8"]
    BOARD --> BOXES["(Optional — boxes already\nconstrained by initialisation)"]
    BOARD --> CAGES["Cage violations (Killer)\nΣ 1 if sum(cage)≠target\n  or duplicate in cage"]

    ROWS & COLS & BOXES & CAGES --> TOTAL["total_violations = Σ all above"]
    TOTAL --> SA_E["SA energy E = total_violations\n(minimise → 0)"]
    TOTAL --> GA_F["GA fitness = max_possible − total_violations\n(maximise → max_possible)"]

    style SA_E fill:#ffd0d0
    style GA_F fill:#d0ffd0
```

---

## Heuristic Comparison

| | DFID | A\* h₁ | A\* h₂ (MRV) | SA | GA |
|---|---|---|---|---|---|
| Informed | No | Weak | Strong | Yes (local) | Yes (population) |
| Admissible | — | Yes | Yes | N/A | N/A |
| Guides search | No | Slightly | Strongly | Via ΔE | Via fitness |
| Complexity | O(1) | O(1) | O(n) | O(n) | O(N·n) |
| Helps with hard puzzles | No | Little | Yes | Yes (restarts) | Yes (diversity) |

---

## Why MRV Works Well for Sudoku

```mermaid
graph LR
    subgraph "Without MRV"
        W1["Try (0,0): 9 branches"]
        W1 --> W2["Try (0,1): up to 9 branches each"]
        W2 --> W3["Explore ~9^k nodes before detecting contradiction"]
    end

    subgraph "With MRV  (fail-first)"
        M1["Find cell with domain size 1 → assign immediately"]
        M1 --> M2["Find cell with domain size 2 → only 2 branches"]
        M2 --> M3["Contradiction detected close to root"]
    end

    style M3 fill:#90EE90,stroke:#2d6a2d
    style W3 fill:#ffcccc,stroke:#cc0000
```

MRV implements a **fail-first** strategy: cells most likely to cause a contradiction are tried first, cutting large portions of the search tree early.

---

## Killer Sudoku — Extra Constraint Propagation

For A\*, cage constraints allow additional pruning beyond MRV:

```
For a cage with target T and cells {c₁, c₂, ..., cₖ}:

  — min achievable sum  = Σ min(domain(cᵢ))
  — max achievable sum  = Σ max(domain(cᵢ))

  If T < min_sum  OR  T > max_sum → prune entire branch
```

This is integrated into h₂ to make it **Killer-aware** without losing admissibility.
