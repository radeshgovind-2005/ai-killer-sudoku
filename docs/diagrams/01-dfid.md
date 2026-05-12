# Depth-First Iterative Deepening (DFID)

DFID runs DFS repeatedly with an increasing depth limit.
It has the **memory efficiency of DFS** (O(d)) and the **completeness of BFS**.

---

## Algorithm Flowchart

```mermaid
flowchart TD
    START([Start]) --> INIT["depth_limit = 0"]
    INIT --> DFS

    DFS["DFS(root, depth_limit)"] --> CUTOFF{Depth limit\nreached?}
    CUTOFF -- Yes --> RETURN_CUT["Return CUTOFF"]
    CUTOFF -- No --> GOAL{Is current node\na goal?}
    GOAL -- Yes --> SOLUTION([Return Solution])
    GOAL -- No --> EXPAND["Expand children"]
    EXPAND --> CHILD{Any child\nreturns solution?}
    CHILD -- Yes --> SOLUTION
    CHILD -- All CUTOFF --> RETURN_CUT
    CHILD -- Fail --> RETURN_FAIL["Return FAIL"]

    RETURN_CUT --> INC["depth_limit += 1"]
    RETURN_FAIL --> INC
    INC --> DFS
```

---

## Search Tree — How the Depth Limit Grows

Each iteration re-expands shallower nodes. The **overhead is small** because most nodes are at the deepest level (branching factor b: ~b^d nodes total vs ~b^(d-1) re-expanded nodes).

```mermaid
graph TD
    subgraph it1["Iteration 1 — limit = 1  (3 nodes visited)"]
        R1(("S")) --> A1(("A"))
        R1 --> B1(("B"))
        A1 -. CUTOFF .-> X1(("..."))
        B1 -. CUTOFF .-> Y1(("..."))
    end

    subgraph it2["Iteration 2 — limit = 2  (7 nodes visited)"]
        R2(("S")) --> A2(("A"))
        R2 --> B2(("B"))
        A2 --> C2(("C"))
        A2 --> D2(("D"))
        B2 --> E2(("E"))
        B2 --> F2(("F ★"))
    end

    style F2 fill:#90EE90,stroke:#2d6a2d,color:#000
    style it2 fill:#f0fff0,stroke:#2d6a2d
```

> **★ Goal found** at depth 2, second iteration.

---

## DFID vs DFS vs BFS

```mermaid
graph LR
    subgraph mem["Memory Usage"]
        DFS_M["DFS\nO(b·d)"]
        BFS_M["BFS\nO(b^d)"]
        DFID_M["DFID\nO(d)"]
    end

    subgraph comp["Completeness"]
        DFS_C["DFS\nIncomplete\n(infinite branches)"]
        BFS_C["BFS\nComplete"]
        DFID_C["DFID\nComplete"]
    end

    DFID_M --> |best of both| DFID_C
```

---

## Applied to Sudoku

```mermaid
flowchart TD
    STATE["Board state\n(partial assignment)"] --> PICK["Pick next empty cell\n(left-to-right, top-to-bottom)"]
    PICK --> TRY["Try digit d ∈ {1..9}"]
    TRY --> VALID{Satisfies row,\ncol, box\nconstraints?}
    VALID -- No --> NEXT_D["Try next digit"]
    NEXT_D --> EMPTY{All digits\nexhausted?}
    EMPTY -- Yes --> BACKTRACK["Backtrack\n(undo last assignment)"]
    EMPTY -- No --> TRY
    VALID -- Yes --> DEEPER["Recurse deeper\n(place next cell)"]
    DEEPER --> DEEPER_GOAL{All 81 cells\nfilled?}
    DEEPER_GOAL -- Yes --> DONE(["Solution found!"])
    DEEPER_GOAL -- No --> PICK

    BACKTRACK --> PREV["Return to previous cell\nand try next digit"]
    PREV --> NEXT_D
```

### Killer Sudoku Extension

On top of the standard constraints, each assignment also checks:

```mermaid
flowchart LR
    ASSIGN["Assign value v\nto cell (r,c)"] --> CAGE["Find cage C\ncontaining (r,c)"]
    CAGE --> DUP{Duplicate\nin cage?}
    DUP -- Yes --> FAIL(["Prune branch"])
    DUP -- No --> SUM{Partial sum\n> target?}
    SUM -- Yes --> FAIL
    SUM -- No --> OK(["Continue DFS"])
```

---

## Complexity

| Metric | Value |
|--------|-------|
| Time | O(b^d) — same as BFS |
| Space | **O(d)** — only current path |
| Completeness | Yes (finite branching) |
| Optimality | Yes (unit step cost) |

> For Sudoku: branching factor b ≤ 9, depth d = number of empty cells (up to 81).
