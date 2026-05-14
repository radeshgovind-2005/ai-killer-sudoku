# Report Notes — Algorithm Design Decisions

> Capture every non-obvious design choice here as you implement. The report requires justification of each decision.

---

## DFID

### Why DFID and not plain DFS?
- DFID gives completeness (guaranteed to find a solution if one exists) with O(depth) memory
- For Sudoku the depth is bounded by 81, so the iterative deepening overhead is negligible
- The depth bound here is essentially the number of empty cells — the algorithm degenerates to constraint-driven DFS in practice
- Report framing: "DFID's memory advantage over BFS is the motivation; its practical behavior on Sudoku is depth-bounded DFS with constraint propagation"

### MRV (Minimum Remaining Values) in next_empty
- Choosing the most-constrained cell first dramatically reduces the branching factor
- Without MRV: branching factor ≤ 9, search space 9^81 in the worst case
- With MRV: cells with 1 candidate are placed deterministically (no branching), cells with 2 candidates branch by 2, etc.
- Effect: often reduces medium-hard puzzles from timeout to milliseconds
- This is forward checking — worth naming in the report

### What to measure
- Time to solve (wall clock, use `get_time/1` in Prolog)
- Nodes expanded (increment a global counter via `nb_setval/nb_getval`)
- Whether MRV is on or off — run without MRV first to show the difference

---

## A*

### Why the open list is a heap and not a sorted list
- Sorted list insertion is O(N); heap insertion is O(log N)
- For hard puzzles the open list can grow to millions of nodes
- SWI-Prolog's `library(heaps)` provides a binary heap — use it

### Closed list implementation
- Plain Prolog list with `member/2` check: O(N) per lookup — acceptable for small puzzles
- For large open lists, `asserta` into a dynamic predicate is faster: O(1) write, O(1) read with indexing
- Report: acknowledge the trade-off, choose the simpler approach unless benchmarks show it is a bottleneck

### Why A* may be impractical on hard puzzles
- The open list size is exponential in the worst case (explores many states at similar f values)
- Without aggressive constraint propagation (arc consistency), A* on expert Sudoku may exhaust memory
- Report honestly: "A* with the admissible heuristic and forward checking solves easy/medium puzzles efficiently. On expert puzzles it either succeeds slowly or exhausts memory. This motivates the optimization approaches (SA, GA)."

### g(n) cost model
- Unit cost: g(n) = number of cells placed = depth in the search tree
- Alternative: g(n) = 0 for all nodes (reduces A* to greedy best-first search)
- Using g(n) = depth ensures optimality (finds solution at minimum depth = minimum assignments) — but for Sudoku all solutions are at the same depth (81), so optimality is trivially satisfied
- Report: use g(n) = depth for correctness, acknowledge that it does not change which solution is found (all solutions are at depth 81 for a complete board)

---

## Simulated Annealing

### Why box-swap as the neighbor operator
- Alternative operators: swap any two cells on the board, or change one cell to a random value
- Box-swap preserves the box uniqueness constraint by construction (swapping within a box that already has each digit exactly once still has each digit once)
- This reduces the cost function to only row + column violations (boxes always contribute 0)
- Halves the search space dimensionality — the optimizer only needs to fix 2 of 3 constraint types
- Reference: Peter Norvig's Sudoku essay; Mantere & Koljonen (2007) on SA for Sudoku

### Initialization
- Each box is filled independently: take the 9 - k given values, fill remaining cells with the missing digits in random order
- This guarantees a complete board where every box is already valid
- Avoids the SA having to fix box violations at all

### Temperature schedule
- T_initial = 1.0, cooling_rate = 0.9995, T_min = 0.001
- These are empirical starting points — tune based on benchmark results
- A faster cooling rate converges quicker but gets stuck in local minima more often
- Record the final temperature and iteration count when a solution is found

### Restart strategy
- If cost does not improve for K=1000 consecutive iterations, reinitialize the board (new random box fills)
- Keep track of the best board seen across all restarts
- Report: restarts are essential for hard puzzles — show the improvement in solve rate with vs without

---

## Genetic Algorithm

### Box-preserving crossover
- Alternative: uniform crossover (randomly pick each cell from either parent)
- Problem with uniform crossover: it can destroy valid box configurations
- Box-preserving crossover: for each 3x3 box independently, copy the entire box from parent 1 or parent 2 (random coin flip)
- This maintains box validity in offspring (if parents have valid boxes, offspring do too)
- Row/column constraints are recombined, which is the point — offspring may have different row/column errors than either parent

### Elitism
- Always carry the top 2 chromosomes (by fitness) into the next generation unchanged
- Prevents regression — the best solution found so far is never lost
- Common GA practice; worth mentioning in the report

### Population diversity
- Tournament selection with k=3 maintains pressure without premature convergence
- If all chromosomes converge to the same local minimum, the GA stagnates
- Mitigation: inject random chromosomes when diversity (measured by unique fitness values) drops below a threshold

### Fitness landscape
- Sudoku has many local optima — it is not a smooth landscape
- GA is more likely to escape local optima than SA because crossover can jump across the landscape
- SA is typically faster per run but GA may find solutions that SA misses on hard instances
- Report: compare success rate and solve time across difficulty levels

---

## Killer Sudoku Extension

### Cage constraint as additional pruning
- During search: if all cells of a cage are filled, verify sum = target and all values unique
- During search (partial): if some cells are filled, the partial sum must not exceed target; remaining empty cells must be able to reach target (bounds check)
- The partial check: partial_sum + 1*(remaining) ≤ target ≤ partial_sum + 9*(remaining)
  - Also exclude already-used values from the remaining capacity
- This is constraint propagation at the cage level — prune early and hard

### Cage data structure
- `cage(TargetSum, Cells)` where Cells is a list of `(Row,Col)` pairs
- Separate from the board — the board is still a flat 81-list
- Cages are passed as an extra argument to the solver predicates

### Interaction with standard constraints
- Cage uniqueness constraint is stronger than standard Sudoku in some cases: a cage that spans a full row automatically enforces the row constraint for those cells
- In practice, the cage check runs after the standard placement check — no special interaction needed

### For SA/GA with Killer Sudoku
- Add cage violations to the cost function: for each cage, violations = sum_error + uniqueness_error
  - sum_error: |actual_sum - target_sum|
  - uniqueness_error: number of duplicate values in cage
- The box-swap operator may still be used; cage validity is enforced by the cost function, not by construction
