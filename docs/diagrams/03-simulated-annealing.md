# Simulated Annealing (SA)

Inspired by metallurgical annealing: a hot system can escape local minima;
as temperature drops it settles into a (near-)global minimum.

---

## Core Idea

```
Start with a random (complete) board.
Repeatedly make small changes (moves).
  — If the move improves the score  → always accept it.
  — If the move worsens the score   → accept it with probability e^(-ΔE / T).
Slowly lower T until no bad moves are accepted.
```

---

## Algorithm Flowchart

```mermaid
flowchart TD
    START([Start]) --> INIT["Generate random\ncomplete board S\nSet T = T_max"]
    INIT --> EVAL["E = violations(S)"]
    EVAL --> SOLVED{E = 0?}
    SOLVED -- Yes --> DONE(["Solution found!"])
    SOLVED -- No --> NEIGHBOR["Generate neighbour S'\nby swapping two cells\nin the same box"]
    NEIGHBOR --> DELTA["ΔE = violations(S') − violations(S)"]
    DELTA --> BETTER{ΔE < 0?}
    BETTER -- Yes --> ACCEPT["Accept S' → S = S'"]
    BETTER -- No --> PROB["Accept with probability\np = e^(−ΔE / T)"]
    PROB --> LUCKY{random() < p?}
    LUCKY -- Yes --> ACCEPT
    LUCKY -- No --> REJECT["Reject S' — keep S"]
    ACCEPT --> COOL["T = T × α  (cool down)"]
    REJECT --> COOL
    COOL --> FROZEN{T < T_min?}
    FROZEN -- No --> NEIGHBOR
    FROZEN -- Yes --> RESTART["Restart?\n(reheat)"]
    RESTART -- Yes --> INIT
    RESTART -- No --> BEST(["Return best S found"])
```

---

## Acceptance Probability — e^(−ΔE / T)

Higher temperature → more likely to accept worse moves (exploration).
Lower temperature → only accept improvements (exploitation).

```mermaid
xychart-beta
    title "Acceptance probability vs ΔE for different temperatures"
    x-axis "ΔE (worsening)" [1, 2, 3, 4, 5, 6, 7, 8]
    y-axis "P(accept)" 0 --> 1
    line [0.37, 0.14, 0.05, 0.02, 0.007, 0.002, 0.001, 0.0003]
    line [0.61, 0.37, 0.22, 0.14, 0.08, 0.05, 0.03, 0.02]
    line [0.78, 0.61, 0.47, 0.37, 0.29, 0.22, 0.17, 0.14]
```

> Line 1 = T=1 (cold), Line 2 = T=2, Line 3 = T=3 (hot)

---

## Temperature Schedule

```mermaid
flowchart LR
    subgraph "Geometric Cooling  (most common)"
        GC["T(k) = T₀ × αᵏ\nα ∈ (0.8, 0.99)\nk = iteration number"]
    end

    subgraph "Linear Cooling"
        LC["T(k) = T₀ − k × δ"]
    end

    subgraph "Reheating"
        RH["If stuck in local min:\nreset T = T₀ × β\nβ ∈ (0.5, 1)"]
    end

    GC --> |"most robust"| PICK(["Use geometric\nfor Sudoku"])
    LC --> PICK
    RH --> |"improves hard puzzles"| PICK

    style PICK fill:#FFD700,stroke:#b8860b,color:#000
```

---

## Energy Landscape

```mermaid
graph LR
    subgraph "Energy  E = violations(board)"
        direction TB
        H1["High E\n(many violations)"]
        LM["Local minimum\n(SA may escape this)"]
        GM["Global minimum\nE = 0\n(solution!)"]
    end

    H1 -->|"downhill always accepted"| LM
    LM -->|"uphill accepted with prob e^-ΔE/T"| H1
    LM -->|"continue search"| GM

    style GM fill:#90EE90,stroke:#2d6a2d,color:#000
    style LM fill:#FFD700,stroke:#b8860b,color:#000
```

---

## Evaluation Function (Violations)

```
violations(board) = Σ row_violations
                  + Σ col_violations
                  + Σ box_violations
                  [+ Σ cage_violations  ← Killer Sudoku]

row_violations(r)  = 9 − |unique values in row r|
col_violations(c)  = 9 − |unique values in col c|
box_violations(b)  = 9 − |unique values in box b|
cage_violation(g)  = 1 if sum(cage) ≠ target OR duplicate in cage
```

**Goal: violations = 0**

---

## Move Operator — Box Swap

```mermaid
graph LR
    subgraph before["Before swap"]
        B1["Box 5\n┌─────┐\n│ 3 7 1│\n│ 4 2 8│\n│ 6 5 9│\n└─────┘"]
    end

    SWAP["Swap (r1,c1)=3\nand (r2,c2)=7\nwithin same box"]

    subgraph after["After swap"]
        A1["Box 5\n┌─────┐\n│ 7 3 1│\n│ 4 2 8│\n│ 6 5 9│\n└─────┘"]
    end

    B1 --> SWAP --> A1
```

> Swapping within a box preserves digit uniqueness per box — only row/col violations change.

---

## Parameters Tuning

| Parameter | Typical Range | Effect |
|-----------|--------------|--------|
| T₀ (initial temp) | 1.0 – 5.0 | Higher → more exploration at start |
| T_min | 0.001 – 0.1 | Lower → longer run, better quality |
| α (cooling rate) | 0.90 – 0.999 | Closer to 1 → slower cooling |
| Iterations per T | 100 – 10 000 | More → better but slower |
| Restarts | 3 – 20 | Escape repeated local minima |
