"""Shared puzzle paths for the Python solvers."""

from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
INPUT_DIR = PROJECT_ROOT / "data" / "input"

CLASSIC_EASY_01 = INPUT_DIR / "classic_easy_01.txt"
