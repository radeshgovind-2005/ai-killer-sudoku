"""Shared Sudoku board utilities for the Python solvers.

The file format is shared with the Prolog implementation:
- 9 lines with 9 characters each
- digits 1-9 for fixed values
- 0 or . for empty cells

Killer Sudoku format (load_killer_puzzle):
- Optional % comment lines
- 9 board rows (digits/dots)
- cage(Sum,[(R1,C1),(R2,C2),...]).  lines
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Iterable

BOARD_SIZE = 9
BOX_SIZE = 3
BOARD_LENGTH = BOARD_SIZE * BOARD_SIZE
Board = list[int]

# A cage is (target_sum, [(row, col), ...]) — rows and cols are 1-indexed.
Cage = tuple[int, list[tuple[int, int]]]


def empty_board() -> Board:
    return [0] * BOARD_LENGTH


def is_valid_board(board: Board) -> bool:
    return len(board) == BOARD_LENGTH and all(isinstance(value, int) and 0 <= value <= 9 for value in board)


def board_from_rows(rows: Iterable[Iterable[int]]) -> Board:
    flat_board = [value for row in rows for value in row]
    if not is_valid_board(flat_board):
        raise ValueError("Board must contain exactly 81 integer values between 0 and 9.")
    return flat_board


def board_from_string(text: str) -> Board:
    relevant = [char for char in text if char.isdigit() or char == "."]
    board = [0 if char == "." else int(char) for char in relevant]
    if not is_valid_board(board):
        raise ValueError("Puzzle text must define exactly 81 cells.")
    return board


def load_board(path: str | Path) -> Board:
    return board_from_string(Path(path).read_text(encoding="utf-8"))


def cell(board: Board, row: int, col: int) -> int:
    _validate_coordinate(row)
    _validate_coordinate(col)
    _validate_board(board)
    return board[(row - 1) * BOARD_SIZE + (col - 1)]


def set_cell(board: Board, row: int, col: int, value: int) -> Board:
    _validate_coordinate(row)
    _validate_coordinate(col)
    _validate_value(value)
    _validate_board(board)
    new_board = list(board)
    new_board[(row - 1) * BOARD_SIZE + (col - 1)] = value
    return new_board


def row(board: Board, row_number: int) -> list[int]:
    _validate_coordinate(row_number)
    _validate_board(board)
    start = (row_number - 1) * BOARD_SIZE
    return board[start : start + BOARD_SIZE]


def column(board: Board, col_number: int) -> list[int]:
    _validate_coordinate(col_number)
    _validate_board(board)
    return [cell(board, row_number, col_number) for row_number in range(1, BOARD_SIZE + 1)]


def box_index(row: int, col: int) -> int:
    _validate_coordinate(row)
    _validate_coordinate(col)
    return ((row - 1) // BOX_SIZE) * BOX_SIZE + ((col - 1) // BOX_SIZE)


def box_cells(board: Board, box_number: int) -> list[int]:
    if not 0 <= box_number < BOARD_SIZE:
        raise ValueError("Box index must be between 0 and 8.")
    _validate_board(board)
    start_row = (box_number // BOX_SIZE) * BOX_SIZE + 1
    start_col = (box_number % BOX_SIZE) * BOX_SIZE + 1
    return [
        cell(board, start_row + row_offset, start_col + col_offset)
        for row_offset in range(BOX_SIZE)
        for col_offset in range(BOX_SIZE)
    ]


def format_board(board: Board) -> str:
    _validate_board(board)
    lines = []
    for row_number in range(1, BOARD_SIZE + 1):
        values = ["." if value == 0 else str(value) for value in row(board, row_number)]
        lines.append(" ".join(values))
    return "\n".join(lines)


def print_board(board: Board) -> None:
    print(format_board(board))


def _validate_board(board: Board) -> None:
    if not is_valid_board(board):
        raise ValueError("Board must contain exactly 81 integer values between 0 and 9.")


def _validate_coordinate(value: int) -> None:
    if not 1 <= value <= BOARD_SIZE:
        raise ValueError("Coordinates must be between 1 and 9.")


def _validate_value(value: int) -> None:
    if not isinstance(value, int) or not 0 <= value <= 9:
        raise ValueError("Cell values must be integers between 0 and 9.")


def load_killer_puzzle(path: str | Path) -> tuple[Board, list[Cage]]:
    """Parse a Killer Sudoku file into (board, cages).

    File format (same as killer_easy_01.txt):
        % optional comment lines
        000000000       <- 9 board rows; 0 or . means empty cell
        ...
        cage(12,[(1,1),(1,2),(1,3)]).
        ...

    Returns:
        board  — flat 81-element list (0 = empty / no givens for pure killer)
        cages  — list of (target_sum, [(row, col), ...]) with 1-based indices
    """
    text = Path(path).read_text(encoding="utf-8")
    board_lines: list[str] = []
    cages: list[Cage] = []

    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("%"):
            continue
        m = re.match(r"cage\((\d+),\s*\[([^\]]+)\]\)", stripped.rstrip("."))
        if m:
            target = int(m.group(1))
            cells = [
                (int(r), int(c))
                for r, c in re.findall(r"\((\d+),\s*(\d+)\)", m.group(2))
            ]
            cages.append((target, cells))
        elif re.match(r"^[\d.]+$", stripped):
            board_lines.append(stripped)

    board = board_from_string("\n".join(board_lines[:BOARD_SIZE]))
    return board, cages


def cage_cost(board: Board, cages: list[Cage]) -> int:
    """Count cage constraint violations on a complete board.

    Per cage:
      +1 if the sum of cage values != target sum
      +(len - len(set)) for duplicate values within the cage

    Box constraints are always satisfied by construction (box-swap operator),
    so this only needs to check cage-specific rules on top of row/column cost.
    """
    violations = 0
    for target, cells in cages:
        vals = [board[(r - 1) * BOARD_SIZE + (c - 1)] for r, c in cells]
        if sum(vals) != target:
            violations += 1
        violations += len(vals) - len(set(vals))
    return violations
