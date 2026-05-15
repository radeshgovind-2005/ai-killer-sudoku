#!/usr/bin/env python3
"""Genetic Algorithm solver for Sudoku.

Chromosome:
  A complete 9×9 board initialised the same way as SA: each 3×3 box contains
  exactly 1–9, so box constraints are always satisfied. Only mutable (non-given)
  cells are touched by crossover and mutation.

Fitness:
  fitness = -cost(board)  where cost counts row + column violations.
  A solved board has fitness 0. The GA maximises fitness (minimises cost).

Selection:
  Tournament selection of size k=3 — compare k random individuals, take best.

Crossover (box-preserving):
  For each of the nine 3×3 boxes, randomly inherit the box entirely from
  parent1 or parent2. Given cells remain fixed. This keeps box constraints
  satisfied in the child.

Mutation:
  With probability mutation_rate, swap two non-given cells within a random box
  (same as the SA operator). Applied per child after crossover.

Elitism:
  The top `elite` individuals survive unchanged to the next generation.

Restart:
  If the best fitness has not improved for `stagnation_limit` generations,
  reinitialise the entire population except the current best.

CLI:
  python3 src/python/ga_solver.py --puzzle easy
  python3 src/python/ga_solver.py --puzzle expert --pop 300 --generations 5000
"""

import argparse
import random
import time
from pathlib import Path

from board import Board, Cage, load_board, load_killer_puzzle, print_board, format_board, BOARD_SIZE, BOX_SIZE
from puzzles import PUZZLES, KILLER_PUZZLES, OUTPUT_DIR
from sa_solver import get_givens, initialize, cost


# ── GA operators ───────────────────────────────────────────────────────────────

def fitness(board: Board, cages: list[Cage] | None = None) -> int:
    return -cost(board, cages)


def tournament_select(population: list[Board], fitnesses: list[int], k: int = 3) -> Board:
    contestants = random.sample(range(len(population)), k)
    winner = max(contestants, key=lambda i: fitnesses[i])
    return population[winner]


def _box_indices(box: int) -> list[int]:
    sr = (box // BOX_SIZE) * BOX_SIZE
    sc = (box % BOX_SIZE) * BOX_SIZE
    return [sr * BOARD_SIZE + r * BOARD_SIZE + sc + c
            for r in range(BOX_SIZE) for c in range(BOX_SIZE)]


def crossover(parent1: Board, parent2: Board, givens: frozenset[int]) -> Board:
    """Box-preserving crossover: inherit each box from one parent at random."""
    child = list(parent1)
    for box in range(BOARD_SIZE):
        if random.random() < 0.5:
            for i in _box_indices(box):
                if i not in givens:
                    child[i] = parent2[i]
    return child


def mutate(board: Board, givens: frozenset[int], swaps: int = 2) -> Board:
    """Apply `swaps` random within-box swaps.

    Multiple swaps per mutation helps escape narrow local optima that a
    single swap cannot break out of.
    """
    new_board = list(board)
    for _ in range(swaps):
        for _ in range(100):
            box = random.randrange(BOARD_SIZE)
            indices = _box_indices(box)
            mutable = [i for i in indices if i not in givens]
            if len(mutable) >= 2:
                i, j = random.sample(mutable, 2)
                new_board[i], new_board[j] = new_board[j], new_board[i]
                break
    return new_board


# ── Core algorithm ─────────────────────────────────────────────────────────────

def genetic_algorithm(
    board: Board,
    givens: frozenset[int],
    pop_size: int = 200,
    max_gen: int = 10000,
    mutation_rate: float = 0.25,
    elite: int = 2,
    stagnation_limit: int = 2000,
    cages: list[Cage] | None = None,
) -> tuple[Board, int, int]:
    """Run GA. Returns (best_board, generation_found, best_fitness)."""
    population = [initialize(board, givens) for _ in range(pop_size)]
    fitnesses = [fitness(b, cages) for b in population]

    best_idx = max(range(pop_size), key=lambda i: fitnesses[i])
    best_board = list(population[best_idx])
    best_fit = fitnesses[best_idx]
    best_gen = 0
    stagnation = 0

    for gen in range(1, max_gen + 1):
        if best_fit == 0:
            break

        # Sort by fitness descending for elitism
        ranked = sorted(range(pop_size), key=lambda i: fitnesses[i], reverse=True)
        new_population: list[Board] = [list(population[i]) for i in ranked[:elite]]

        while len(new_population) < pop_size:
            p1 = tournament_select(population, fitnesses)
            p2 = tournament_select(population, fitnesses)
            child = crossover(p1, p2, givens)
            if random.random() < mutation_rate:
                child = mutate(child, givens)
            new_population.append(child)

        population = new_population
        fitnesses = [fitness(b, cages) for b in population]

        gen_best_idx = max(range(pop_size), key=lambda i: fitnesses[i])
        gen_best_fit = fitnesses[gen_best_idx]

        if gen_best_fit > best_fit:
            best_fit = gen_best_fit
            best_board = list(population[gen_best_idx])
            best_gen = gen
            stagnation = 0
        else:
            stagnation += 1

        if stagnation >= stagnation_limit:
            # Keep best individual; reinitialise rest
            saved = list(best_board)
            population = [initialize(board, givens) for _ in range(pop_size - 1)]
            population.append(saved)
            fitnesses = [fitness(b, cages) for b in population]
            stagnation = 0

    return best_board, best_gen, best_fit


# ── CLI ────────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="Genetic Algorithm Sudoku solver")
    parser.add_argument("--puzzle", choices=list(PUZZLES), default="easy",
                        help="Puzzle difficulty (default: easy)")
    parser.add_argument("--pop", type=int, default=200,
                        help="Population size (default: 200)")
    parser.add_argument("--generations", type=int, default=10000,
                        help="Max generations (default: 5000)")
    parser.add_argument("--runs", type=int, default=1,
                        help="Number of independent runs (default: 1)")
    parser.add_argument("--seed", type=int, default=None,
                        help="Random seed for reproducibility")
    args = parser.parse_args()

    if args.seed is not None:
        random.seed(args.seed)

    path = PUZZLES[args.puzzle]
    if args.puzzle in KILLER_PUZZLES:
        board, cages = load_killer_puzzle(path)
    else:
        board, cages = load_board(path), None

    givens = get_givens(board)

    print(f"Puzzle ({args.puzzle}):")
    print_board(board)
    print()

    results = []
    for run in range(1, args.runs + 1):
        t0 = time.perf_counter()
        best, best_gen, best_fit = genetic_algorithm(
            board, givens,
            pop_size=args.pop,
            max_gen=args.generations,
            cages=cages,
        )
        elapsed = time.perf_counter() - t0

        solved = best_fit == 0
        results.append((solved, best_fit, best_gen, elapsed, best))
        status = "SOLVED" if solved else f"UNSOLVED (cost={-best_fit})"
        print(f"Run {run}/{args.runs}: {status} | gen={best_gen} | time={elapsed:.3f}s")

    best_run = max(results, key=lambda r: r[1])
    print()
    if best_run[0]:
        print("Solution:")
        print_board(best_run[4])
    else:
        print(f"Best board found (cost={-best_run[1]}):")
        print_board(best_run[4])

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    log_path = OUTPUT_DIR / "ga_results.txt"
    with log_path.open("a") as f:
        f.write(f"\n=== GA  puzzle={args.puzzle}  pop={args.pop}  max_gen={args.generations}  runs={args.runs} ===\n")
        for i, (solved, bf, bg, elapsed, _) in enumerate(results, 1):
            status = "SOLVED" if solved else f"cost={-bf}"
            f.write(f"  run {i}: {status}  gen={bg}  time={elapsed:.3f}s\n")
        f.write(f"  best_fitness={best_run[1]}\n")
        f.write(f"  best_solution:\n{format_board(best_run[4])}\n")


if __name__ == "__main__":
    main()
