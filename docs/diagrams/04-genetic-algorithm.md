# Genetic Algorithm (GA)

GA maintains a **population** of candidate solutions and evolves them over generations
using selection, crossover, and mutation — mimicking natural evolution.

---

## Evolutionary Cycle

```mermaid
flowchart TD
    INIT["Initialise population\n(N random complete boards)"] --> EVAL

    EVAL["Evaluate fitness\nfor each individual"] --> CONVERGED

    CONVERGED{Best fitness\n= 0 violations?}
    CONVERGED -- Yes --> DONE(["Return solution"])
    CONVERGED -- No --> SELECT

    SELECT["Selection\n(tournament / roulette wheel)\nChoose parents proportional to fitness"] --> CROSS

    CROSS["Crossover\nCombine two parents\nto create offspring"] --> MUTATE

    MUTATE["Mutation\nRandom swap within a box\nwith probability p_m"] --> REPLACE

    REPLACE["Replace population\n(elitism: keep best individuals)"] --> EVAL
```

---

## Population Initialisation

```mermaid
graph LR
    subgraph "Each individual = complete 9×9 board"
        I1["Individual 1\nAll 81 cells filled\nClues fixed, free cells random"]
        I2["Individual 2"]
        I3["Individual 3"]
        DOTS["  ...  "]
        IN["Individual N"]
    end

    I1 & I2 & I3 & DOTS & IN --> POP[("Population\n(N individuals)")]
```

> Clue cells (given digits) are **always fixed** — only free cells vary.

---

## Fitness Function

```
fitness(individual) = max_score − violations(individual)

violations = Σ row_violations + Σ col_violations
             [+ Σ cage_violations  ← Killer Sudoku]

max_score  = 9 rows × 9 + 9 cols × 9 = 162  (no box violations by construction)
```

Higher fitness = fewer violations = better board. **Target: fitness = max_score**.

```mermaid
graph LR
    subgraph "Fitness Range"
        BAD["Fitness = 0\n(worst — all violated)"]
        MED["Fitness = 81\n(half rows/cols correct)"]
        GOOD["Fitness = 162\n(solution! 0 violations)"]
    end

    BAD --> MED --> GOOD
    style GOOD fill:#90EE90,stroke:#2d6a2d,color:#000
    style BAD fill:#ffcccc,stroke:#cc0000
    style MED fill:#FFD700,stroke:#b8860b,color:#000
```

---

## Selection — Tournament

```mermaid
flowchart LR
    POP[("Population\n(N individuals)")] --> SAMPLE["Randomly sample\nk individuals\n(tournament size k=5)"]
    SAMPLE --> BEST["Pick individual\nwith highest fitness"]
    BEST --> PARENT(["Selected parent"])

    style PARENT fill:#90EE90,stroke:#2d6a2d,color:#000
```

> Repeat twice to get two parents for crossover.

---

## Crossover — Row-Based

```mermaid
graph TD
    subgraph "Parent A"
        PA["Row 0: 5 3 4 6 7 8 9 1 2\nRow 1: 6 7 2 1 9 5 3 4 8\nRow 2: ✂ split here ✂\nRow 3: 8 5 9 7 6 1 4 2 3\n..."]
    end

    subgraph "Parent B"
        PB["Row 0: 1 2 9 4 8 3 5 7 6\nRow 1: 8 5 3 7 9 6 1 4 2\nRow 2: ✂ split here ✂\nRow 3: 9 6 1 5 3 7 2 8 4\n..."]
    end

    PA & PB --> CROSS["One-point crossover\nat random row boundary"]

    subgraph "Child"
        CH["Row 0–1 from Parent A\nRow 2–8 from Parent B"]
    end

    CROSS --> CH
    style CH fill:#d0e8ff,stroke:#336699
```

---

## Mutation — Box Swap

```mermaid
flowchart LR
    CELL["For each free cell\nin the individual"]
    CELL --> ROLL{random() < p_m?}
    ROLL -- No --> NEXT["Next cell"]
    ROLL -- Yes --> PICK["Pick another\nrandom free cell\nin the SAME box"]
    PICK --> SWAP["Swap values"]
    SWAP --> NEXT
    NEXT --> DONE(["Mutated individual"])
```

> Mutation rate p_m is typically 0.01 – 0.05.

---

## Elitism

```mermaid
graph LR
    OLD[("Generation G\n(N individuals)")] --> SORT["Sort by fitness ↓"]
    SORT --> KEEP["Keep top E individuals\nunchanged  (E=1–5)"]
    KEEP & NEW_KIDS["N−E new offspring\n(from crossover+mutation)"] --> NEXT_GEN[("Generation G+1\n(N individuals)")]

    style KEEP fill:#90EE90,stroke:#2d6a2d,color:#000
```

Elitism guarantees the best solution found is **never lost**.

---

## Generation Progression

```mermaid
xychart-beta
    title "Average fitness over generations"
    x-axis "Generation" [0, 50, 100, 150, 200, 250, 300]
    y-axis "Avg Fitness (max 162)" 60 --> 162
    line [65, 110, 135, 148, 155, 159, 162]
```

---

## Parameters

| Parameter | Typical Value | Effect |
|-----------|--------------|--------|
| Population size N | 100 – 1000 | Larger → better diversity, slower |
| Crossover rate p_c | 0.7 – 0.9 | Higher → more recombination |
| Mutation rate p_m | 0.01 – 0.05 | Higher → more exploration |
| Tournament size k | 3 – 7 | Larger → stronger selection pressure |
| Elitism E | 1 – 5 | Preserves best solutions |
| Max generations | 1 000 – 10 000 | Stop condition |
