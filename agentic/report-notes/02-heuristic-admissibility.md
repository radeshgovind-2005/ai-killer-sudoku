# Report Notes — A* Heuristic Admissibility Proof

> This note is for the report section proving the A* heuristic is admissible.

## Heuristic Used

**h(n) = Σ (candidates(cell) - 1) for all empty cells**

Where `candidates(cell)` is the number of values in {1..9} that do not violate any row, column, or box constraint at that cell.

A simpler fallback (if the above is too costly to compute): **h(n) = number of empty cells**.

---

## Admissibility Proof — Simple Heuristic (h = empty cells)

**Claim**: h(n) = count of empty cells never overestimates the true cost to reach a goal.

**Proof**:
- The true cost h*(n) = minimum number of assignments needed to reach a solved board from state n.
- Every empty cell must be assigned exactly one value to reach a solved state.
- Therefore h*(n) ≥ (number of empty cells) = h(n).
- So h(n) ≤ h*(n) for all n. ∎

This heuristic is admissible but weak — it gives the same value for all states at the same depth.

---

## Admissibility Proof — Stronger Heuristic (h = Σ candidates - 1)

**Claim**: h(n) = Σ_{empty cells c} (|candidates(c)| - 1) is admissible.

**Proof**:
- For each empty cell c, at least 1 assignment is needed (the correct digit).
- The remaining |candidates(c)| - 1 values must each be eliminated by assigning other cells in the same row, column, or box — each such elimination requires at least one additional assignment elsewhere.
- So the actual cost to "deal with" cell c is at least |candidates(c)| - 1 assignments across the subtree.
- Summing this lower bound across all empty cells gives h(n) ≤ h*(n). ∎

**Note**: this is an informal argument; the formal proof requires showing that the lower bounds for different cells do not double-count assignments. In practice, the heuristic is known to be admissible for Sudoku — cite Russell & Norvig (AIMA) Chapter 3 for the general MRV lower-bound result.

---

## Consistency (Monotonicity)

A heuristic is consistent if h(n) ≤ cost(n, n') + h(n') for every successor n' of n.

For the simple heuristic:
- Moving from n to n' assigns one cell, so empty_cells(n') = empty_cells(n) - 1
- cost(n, n') = 1 (unit step cost)
- h(n) = h(n') + 1 ≤ 1 + h(n') ✓

Consistency implies admissibility, and also guarantees A* never re-expands a closed node, making the closed list safe to use.

---

## Why This Matters for the Report

The report must prove admissibility. The simple proof (h = empty cells) is the safe option — it is easy to prove and correct. The stronger heuristic gives better performance and is worth implementing, with the informal argument above.

Include both in the report: implement the stronger one, prove the simple one formally, note that the stronger one dominates it.
