"""Shared puzzle paths for the Python solvers."""

from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
INPUT_DIR = PROJECT_ROOT / "data" / "input"
OUTPUT_DIR = PROJECT_ROOT / "data" / "output"

CLASSIC_EASY_01 = INPUT_DIR / "classic_easy_01.txt"
CLASSIC_MEDIUM_01 = INPUT_DIR / "classic_medium_01.txt"
CLASSIC_HARD_01 = INPUT_DIR / "classic_hard_01.txt"
CLASSIC_EXPERT_01 = INPUT_DIR / "classic_expert_01.txt"

PUZZLES = {
    "easy": CLASSIC_EASY_01,
    "medium": CLASSIC_MEDIUM_01,
    "hard": CLASSIC_HARD_01,
    "expert": CLASSIC_EXPERT_01,
}
