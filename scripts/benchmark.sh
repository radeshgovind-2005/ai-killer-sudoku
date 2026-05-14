#!/usr/bin/env bash
# benchmark.sh — Run all four solvers on all puzzles and collect results.
#
# Usage (from project root):
#   bash scripts/benchmark.sh
#
# Output:
#   data/output/benchmark_results.txt  — full per-solver per-puzzle log
#   stdout                             — summary table
#
# Requirements:
#   swipl (SWI-Prolog) and python3 must be on PATH.
#   Python dependencies: none beyond stdlib (board.py uses no third-party libs).

set -euo pipefail

# ── Paths ──────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DATA_INPUT="${ROOT}/data/input"
DATA_OUTPUT="${ROOT}/data/output"
RESULTS="${DATA_OUTPUT}/benchmark_results.txt"

mkdir -p "${DATA_OUTPUT}"
> "${RESULTS}"          # truncate on each run

DFID_PL="${ROOT}/src/prolog/dfid.pl"
ASTAR_PL="${ROOT}/src/prolog/astar.pl"
KILLER_PL="${ROOT}/src/prolog/killer_sudoku.pl"
SA_PY="${ROOT}/src/python/sa_solver.py"
GA_PY="${ROOT}/src/python/ga_solver.py"

PUZZLES=("easy" "medium" "hard" "expert")
PL_PUZZLE_FILES=(
    "${DATA_INPUT}/classic_easy_01.txt"
    "${DATA_INPUT}/classic_medium_01.txt"
    "${DATA_INPUT}/classic_hard_01.txt"
    "${DATA_INPUT}/classic_expert_01.txt"
)

PYTHON_RUNS=3          # SA and GA are stochastic — run each 3 times
PROLOG_TIMEOUT=120     # seconds per Prolog solver call

log() { echo "$*" | tee -a "${RESULTS}"; }

separator() { log "──────────────────────────────────────────────────────────────"; }

# ── Header ─────────────────────────────────────────────────────────────────────
separator
log "AI Killer Sudoku — Benchmark Results"
log "Date   : $(date '+%Y-%m-%d %H:%M:%S')"
log "Host   : $(uname -n)"
log "swipl  : $(swipl --version 2>&1 | head -1)"
log "python : $(python3 --version 2>&1)"
separator

# ── Run a Prolog solver ────────────────────────────────────────────────────────
run_prolog() {
    local label="$1"      # "DFID" or "A*"
    local plfile="$2"     # path to .pl file
    local puzzle_path="$3"
    local goal="$4"       # Prolog goal string

    log ""
    log "[${label}] ${puzzle_path##*/}"
    local tmp
    tmp="$(mktemp)"
    if timeout "${PROLOG_TIMEOUT}" swipl -q -s "${plfile}" \
           -g "${goal}" >> "${tmp}" 2>&1; then
        cat "${tmp}" | tee -a "${RESULTS}"
    else
        log "  TIMEOUT (>${PROLOG_TIMEOUT}s) or ERROR"
        cat "${tmp}" >> "${RESULTS}"
    fi
    rm -f "${tmp}"
}

# ── DFID — classic puzzles ─────────────────────────────────────────────────────
separator
log "DFID — classic puzzles"
separator
for i in "${!PUZZLES[@]}"; do
    puzzle="${PUZZLES[$i]}"
    pfile="${PL_PUZZLE_FILES[$i]}"
    run_prolog "DFID" "${DFID_PL}" "${pfile}" \
        "solve_file('${pfile}', _), halt"
done

# ── A* — classic puzzles ───────────────────────────────────────────────────────
separator
log "A* — classic puzzles"
separator
for i in "${!PUZZLES[@]}"; do
    puzzle="${PUZZLES[$i]}"
    pfile="${PL_PUZZLE_FILES[$i]}"
    run_prolog "A*" "${ASTAR_PL}" "${pfile}" \
        "solve_file('${pfile}', _), halt"
done

# ── Killer Sudoku — DFID + A* ──────────────────────────────────────────────────
separator
log "Killer Sudoku (DFID + A*) — easy_01"
separator
log ""
log "[Killer DFID+A*] easy_01"
{
    timeout "${PROLOG_TIMEOUT}" swipl -q -s "${KILLER_PL}" \
        -g "solve_killer_file(easy_01, _), halt" 2>&1 \
        | tee -a "${RESULTS}"
} || log "  TIMEOUT (>${PROLOG_TIMEOUT}s) or ERROR"

# ── SA — classic puzzles ───────────────────────────────────────────────────────
separator
log "Simulated Annealing — classic puzzles (${PYTHON_RUNS} runs each)"
separator
for puzzle in "${PUZZLES[@]}"; do
    log ""
    log "[SA] ${puzzle}"
    python3 "${SA_PY}" --puzzle "${puzzle}" --runs "${PYTHON_RUNS}" \
        2>&1 | tee -a "${RESULTS}"
done

# ── GA — classic puzzles ───────────────────────────────────────────────────────
separator
log "Genetic Algorithm — classic puzzles (${PYTHON_RUNS} runs each)"
separator
for puzzle in "${PUZZLES[@]}"; do
    log ""
    log "[GA] ${puzzle}"
    python3 "${GA_PY}" --puzzle "${puzzle}" --pop 200 \
        --generations 5000 --runs "${PYTHON_RUNS}" \
        2>&1 | tee -a "${RESULTS}"
done

# ── Summary table ──────────────────────────────────────────────────────────────
separator
log ""
log "SUMMARY — see ${RESULTS} for full output"
log ""
log "Prolog solvers:  results include 'Nodes expanded' and 'Elapsed' lines"
log "Python solvers:  results include per-run cost/solved status and time"
log ""
log "Benchmark complete."
separator
