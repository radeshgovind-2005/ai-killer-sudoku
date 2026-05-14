# Report Notes — Paradigm Comparison

> Use this as a source for the report section comparing state-space search vs solution-space optimization.

---

## The Two Paradigms

### State-Space Search (DFID, A*)
- **Search space**: partial assignments (trees of incomplete boards)
- **Start**: the initial puzzle (partially filled board)
- **End**: a complete valid board (goal state)
- **Operator**: assign one digit to one empty cell
- **Guarantee**: complete (DFID) and complete + optimal (A*), assuming the heuristic is admissible
- **Weakness**: exponential memory (A*) or exponential time (DFID without pruning) on hard instances

### Solution-Space Optimization (SA, GA)
- **Search space**: complete assignments (all 81-cell boards, many of which are invalid)
- **Start**: a randomly initialized complete board (often violating many constraints)
- **End**: a complete valid board (zero violations)
- **Operator**: perturbation of the current complete assignment (swap, mutation)
- **Guarantee**: none — the algorithm may not find a solution. But it scales to hard instances
- **Weakness**: stochastic, may get stuck in local minima, cannot prove no solution exists

---

## Why Both Paradigms Are Needed

| Property | DFID | A* | SA | GA |
|---|---|---|---|---|
| Complete | Yes | Yes | No | No |
| Optimal | No | Yes | No | No |
| Memory | O(depth) | O(open list) | O(1) | O(pop × board) |
| Hard puzzles | Times out | OOM | Works | Works |
| Deterministic | Yes | Yes | No | No |

No single algorithm dominates. The right choice depends on the problem instance:
- Easy/medium: DFID and A* are fast and guaranteed
- Hard/expert: SA and GA are practical; search algorithms may not terminate in reasonable time

---

## Why Sudoku Is Hard for Search

- Branching factor: up to 9 per empty cell
- Depth: 81 cells to fill (minus givens)
- Without constraint propagation: 9^(81-givens) states in the worst case
- With MRV and forward checking: reduced dramatically, but still exponential in the worst case
- Expert puzzles (22 givens) have been shown to require non-trivial backtracking even with arc consistency (e.g., AI Escargot, the "world's hardest Sudoku")

---

## Why Killer Sudoku Is Harder

- All standard Sudoku constraints apply
- Additionally: cage sum constraint + cage uniqueness constraint
- More constraints = more pruning opportunities (good for search)
- But also: the cage constraints interact with each other in complex ways, making constraint propagation more expensive per node
- For optimization (SA/GA): the cost function gains additional terms for cage violations, making the landscape rougher (more local optima)

---

## Theoretical Notes for the Report

### DFID completeness argument
DFID is complete because it systematically explores all nodes up to depth d before increasing d. For Sudoku, d ≤ 81, so every reachable state is eventually explored. With valid constraints, states are pruned, but no valid solution state is ever skipped (constraint checking is sound: it only prunes provably invalid states).

### A* optimality argument
A* is optimal when h is admissible. For Sudoku, all solutions are at the same depth (81 cells filled), so optimality in the sense of "minimum cost path" is trivially satisfied — any solution path has the same cost. The practical benefit of A* over DFID is that the heuristic guides it toward promising states, reducing total nodes expanded.

### SA convergence
Simulated Annealing converges in probability to the global optimum as T → 0 very slowly (logarithmic schedule). The geometric cooling schedule used here (T *= r) does not guarantee convergence but is practical. The algorithm may fail on a given run — this is expected and why we run multiple trials.

### GA no free lunch
The No Free Lunch theorem states that no algorithm outperforms random search averaged over all possible problems. GA is better than random search on Sudoku because Sudoku has structure that crossover and selection exploit. The box-preserving crossover exploits Sudoku's box structure directly.
