#!/usr/bin/env python3
"""Simulated Annealing solver for Sudoku.

State representation:
  A complete 9×9 board where every 3×3 box contains exactly the digits 1–9.
  Pre-filled (given) cells are fixed throughout. Only mutable cells move.

Operator (neighbour generation):
  Pick a random 3×3 box, swap two non-given cells within it.
  This preserves box uniqueness by construction, so the cost function only
  needs to count row and column violations.

Cost function:
  cost = sum over rows of (9 - distinct values) + sum over columns of same.
  Range: 0 (solved) to 144 (worst case).

Temperature schedule:
  T_initial → T * cooling_rate per step → stop when T < T_min or cost == 0.
  Stagnation restart: if no improvement for max_stagnation steps, reinitialise
  the board from scratch and partially reheat.

CLI:
  python3 src/python/sa_solver.py --puzzle easy
  python3 src/python/sa_solver.py --puzzle expert --runs 5
"""

import argparse
import math
import random
import time

from board import (Board, Cage, load_board, load_killer_puzzle, cage_cost,
                   print_board, format_board, BOARD_SIZE, BOX_SIZE)
from puzzles import PUZZLES, KILLER_PUZZLES, OUTPUT_DIR


# ── Helpers ────────────────────────────────────────────────────────────────────

def get_givens(board: Board) -> frozenset[int]:
    """Return flat indices of pre-filled (given) cells."""
    return frozenset(i for i, v in enumerate(board) if v != 0)


def initialize(board: Board, givens: frozenset[int]) -> Board:
    """Fill every 3×3 box with remaining values 1–9, keeping givens fixed.

    Boxes are filled independently, so box constraints are satisfied by
    construction. Rows and columns will have violations — that is expected.
    """
    result = list(board)
    for box in range(BOARD_SIZE):
        sr = (box // BOX_SIZE) * BOX_SIZE
        sc = (box % BOX_SIZE) * BOX_SIZE
        indices = [sr * BOARD_SIZE + r * BOARD_SIZE + sc + c
                   for r in range(BOX_SIZE) for c in range(BOX_SIZE)]
        given_values = {result[i] for i in indices if i in givens}
        missing = list(set(range(1, 10)) - given_values)
        random.shuffle(missing)
        empty_in_box = [i for i in indices if i not in givens]
        for idx, val in zip(empty_in_box, missing):
            result[idx] = val
    return result


def cost(board: Board, cages: list[Cage] | None = None) -> int:
    """Count constraint violations on a complete board.

    Always counts row + column duplicate violations (boxes are always satisfied
    by construction thanks to the box-swap operator).  When cages are provided
    (Killer Sudoku mode), cage sum and intra-cage uniqueness violations are
    added on top.
    """
    violations = 0
    for i in range(BOARD_SIZE):
        row_vals = board[i * BOARD_SIZE:(i + 1) * BOARD_SIZE]
        col_vals = board[i::BOARD_SIZE]
        violations += BOARD_SIZE - len(set(row_vals))
        violations += BOARD_SIZE - len(set(col_vals))
    if cages:
        violations += cage_cost(board, cages)
    return violations


def neighbour(board: Board, givens: frozenset[int]) -> Board:
    """Swap two non-given cells within a random 3×3 box."""
    new_board = list(board)
    for _ in range(100):           # safety: retry if chosen box has <2 mutable cells
        box = random.randrange(BOARD_SIZE)
        sr = (box // BOX_SIZE) * BOX_SIZE
        sc = (box % BOX_SIZE) * BOX_SIZE
        indices = [sr * BOARD_SIZE + r * BOARD_SIZE + sc + c
                   for r in range(BOX_SIZE) for c in range(BOX_SIZE)]
        mutable = [i for i in indices if i not in givens]
        if len(mutable) >= 2:
            i, j = random.sample(mutable, 2)
            new_board[i], new_board[j] = new_board[j], new_board[i]
            return new_board
    return new_board               # fallback: unchanged (puzzle with few mutable cells)


# ── Core algorithm ─────────────────────────────────────────────────────────────

def simulated_annealing(
    board: Board,
    givens: frozenset[int],
    T_init: float = 2.0,
    cooling: float = 0.9999,
    T_min: float = 0.001,
    max_iterations: int = 300_000,
    cages: list[Cage] | None = None,
) -> tuple[Board, int, int]:
    """Run SA. Returns (best_board, final_cost, total_iterations).

    Each natural cooling run goes from T_init to T_min (~76 k steps at the
    default cooling rate).  When a run exhausts without finding a solution the
    board is reinitialised and temperature is reset to T_init so the next run
    gets a fresh full annealing schedule.  max_iterations caps the total number
    of steps across all restarts.
    """
    current = initialize(board, givens)
    current_cost = cost(current, cages)
    best = list(current)
    best_cost = current_cost

    T = T_init
    iterations = 0

    while best_cost > 0 and iterations < max_iterations:
        candidate = neighbour(current, givens)
        candidate_cost = cost(candidate, cages)
        delta = candidate_cost - current_cost

        if delta < 0 or random.random() < math.exp(-delta / T):
            current = candidate
            current_cost = candidate_cost
            if current_cost < best_cost:
                best = list(current)
                best_cost = current_cost

        T *= cooling
        iterations += 1

        # Natural run complete: restart from scratch for another full schedule.
        if T < T_min and best_cost > 0:
            current = initialize(board, givens)
            current_cost = cost(current, cages)
            T = T_init

    return best, best_cost, iterations


# ── CLI ────────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="Simulated Annealing Sudoku solver")
    parser.add_argument("--puzzle", choices=list(PUZZLES), default="easy",
                        help="Puzzle difficulty (default: easy)")
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
        best, final_cost, iters = simulated_annealing(board, givens, cages=cages)
        elapsed = time.perf_counter() - t0

        solved = final_cost == 0
        results.append((solved, final_cost, iters, elapsed, best))
        status = "SOLVED" if solved else f"UNSOLVED (cost={final_cost})"
        print(f"Run {run}/{args.runs}: {status} | iters={iters:,} | time={elapsed:.3f}s")

    # Print the best result
    best_run = min(results, key=lambda r: r[1])
    print()
    if best_run[0]:
        print("Solution:")
        print_board(best_run[4])
    else:
        print(f"Best board found (cost={best_run[1]}):")
        print_board(best_run[4])

    # Append to output log
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    log_path = OUTPUT_DIR / "sa_results.txt"
    with log_path.open("a") as f:
        f.write(f"\n=== SA  puzzle={args.puzzle}  runs={args.runs} ===\n")
        for i, (solved, fc, iters, elapsed, _) in enumerate(results, 1):
            status = "SOLVED" if solved else f"cost={fc}"
            f.write(f"  run {i}: {status}  iters={iters}  time={elapsed:.3f}s\n")
        f.write(f"  best_cost={best_run[1]}\n")
        f.write(f"  best_solution:\n{format_board(best_run[4])}\n")


if __name__ == "__main__":
    main()
