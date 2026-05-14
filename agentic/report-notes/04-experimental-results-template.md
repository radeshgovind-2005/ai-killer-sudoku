# Report Notes — Experimental Results Template

> Fill in the actual numbers as you run the benchmarks. These tables go directly into the report.

---

## Puzzle Set

| ID | File | Given Cells | Difficulty |
|---|---|---|---|
| P1 | `classic_easy_01.txt` | ~35 | Easy |
| P2 | `classic_medium_01.txt` | ~30 | Medium |
| P3 | `classic_hard_01.txt` | ~25 | Hard |
| P4 | `classic_expert_01.txt` | ~22 | Expert |
| K1 | `killer_easy_01.txt` | N/A (cages) | Killer Easy |

---

## DFID Results

Run with MRV enabled.

| Puzzle | Solved? | Time (s) | Nodes Expanded |
|---|---|---|---|
| P1 (Easy) | | | |
| P2 (Medium) | | | |
| P3 (Hard) | | | |
| P4 (Expert) | | | |
| K1 (Killer) | | | |

Notes on DFID:
- (fill in: did MRV make a measurable difference? did any puzzle time out?)

---

## A* Results

| Puzzle | Solved? | Time (s) | Nodes Expanded | Open List Peak Size |
|---|---|---|---|---|
| P1 (Easy) | | | | |
| P2 (Medium) | | | | |
| P3 (Hard) | | | | |
| P4 (Expert) | | | | |
| K1 (Killer) | | | | |

Notes on A*:
- (fill in: did open list grow too large? did it run out of memory on expert?)

---

## Simulated Annealing Results

Run 5 times per puzzle. Report mean ± std.

| Puzzle | Solved (of 5) | Mean Time (s) | Std Time | Mean Iterations | Final Cost (best run) |
|---|---|---|---|---|---|
| P1 (Easy) | | | | | |
| P2 (Medium) | | | | | |
| P3 (Hard) | | | | | |
| P4 (Expert) | | | | | |
| K1 (Killer) | | | | | |

Parameters used: T_init=__, cooling_rate=__, T_min=__, max_stagnation=__

Notes on SA:
- (fill in: how many restarts were needed on hard/expert? was reheating useful?)

---

## Genetic Algorithm Results

Run 5 times per puzzle. Report mean ± std.

| Puzzle | Solved (of 5) | Mean Time (s) | Std Time | Mean Generations | Best Fitness Reached |
|---|---|---|---|---|---|
| P1 (Easy) | | | | | |
| P2 (Medium) | | | | | |
| P3 (Hard) | | | | | |
| P4 (Expert) | | | | | |
| K1 (Killer) | | | | | |

Parameters used: pop_size=__, max_gen=__, mutation_rate=__, tournament_k=__

Notes on GA:
- (fill in: did diversity collapse? did elitism help? crossover operator effectiveness?)

---

## Algorithm Comparison Summary

| Algorithm | Complete? | Optimal? | Easy | Medium | Hard | Expert |
|---|---|---|---|---|---|---|
| DFID | Yes | No (first found) | ✓ fast | ✓ | ? | ? |
| A* | Yes | Yes | ✓ fast | ✓ | ? | ✗ OOM |
| SA | No | No | ✓ | ✓ | ✓ | ✓ (probabilistic) |
| GA | No | No | ✓ | ✓ | ✓ | ✓ (probabilistic) |

(Update the ✓/✗/? after running benchmarks.)

---

## Cost Curve — SA (one representative run on expert puzzle)

Record the cost at every 1000 iterations. Plot or table for the report.

| Iteration | Cost |
|---|---|
| 0 | |
| 1000 | |
| 5000 | |
| 10000 | |
| 50000 | |
| ... | |

---

## Convergence — GA (one representative run on expert puzzle)

Record the best fitness per generation (sampled every 100 generations).

| Generation | Best Fitness | Mean Fitness |
|---|---|---|
| 0 | | |
| 100 | | |
| 500 | | |
| 1000 | | |
| ... | | |

---

## What the Report Must Say About These Results

1. **DFID vs A\***: A* expands fewer nodes on easy/medium due to heuristic guidance. On expert puzzles, A*'s open list becomes the bottleneck. DFID with MRV is more memory-efficient.

2. **Search vs Optimization**: SA and GA consistently solve puzzles that DFID/A* time out on. This is the fundamental point of the assignment — completeness vs scalability.

3. **SA vs GA**: SA tends to be faster per run for easy/medium. GA has higher overhead (population evaluation) but may explore more of the landscape. On hard puzzles, GA's crossover can escape local minima that SA gets stuck in.

4. **Stochasticity**: SA and GA results vary across runs. Always report multiple runs and averages — a single run is not a valid experiment.
