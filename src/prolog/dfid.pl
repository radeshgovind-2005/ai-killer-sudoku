:- module(dfid, [solve_dfid/2, solve_file/2]).

:- use_module(sudoku).

% ── DFID Solver ───────────────────────────────────────────────────────────────
%
% Depth-First Iterative Deepening for Sudoku.
%
% State space: partial board assignments (flat 81-element list).
% Operator: place a valid digit in an empty cell.
% Goal: all cells filled (solved/1).
%
% Depth is measured as the number of remaining empty cells to fill.
% The initial depth bound equals the number of empty cells in the puzzle,
% so in practice the iterative loop runs exactly once — DFID degenerates to
% constraint-driven DFS. This is expected: see report-notes/03.
%
% MRV (Minimum Remaining Values) in next_empty/3 picks the most-constrained
% empty cell first, drastically reducing the effective branching factor.
%
% Node counting uses nb_setval/nb_getval (non-backtrackable global state) so
% that nodes expanded on failed branches are also counted.
%
% CLI usage (from project root):
%   swipl -s src/prolog/dfid.pl \
%     -g "solve_file('data/input/classic_easy_01.txt', S), print_board(S), halt"

% solve_dfid(+Board, -Solution)
%
% Entry point. Initialises the node counter and wall-clock timer, runs the
% bounded DFS with increasing depth limits, then prints statistics.
solve_dfid(Board, Solution) :-
    nb_setval(dfid_nodes, 0),
    get_time(Start),
    empty_cells(Board, Empties),
    length(Empties, N),
    between(N, 81, Depth),
    dfid(Board, Depth, Solution), !,
    get_time(End),
    nb_getval(dfid_nodes, Nodes),
    Elapsed is End - Start,
    format("Nodes expanded : ~w~n", [Nodes]),
    format("Elapsed        : ~4f s~n", [Elapsed]).

% dfid(+Board, +DepthLimit, -Solution)
%
% Bounded DFS. Two clauses:
%   1. Base case — board is solved, return it.
%   2. Recursive case — pick the MRV cell, try each valid candidate,
%      recurse with DepthLimit decremented by 1.
%
% Prolog's backtracking is the search engine: when valid_placement/4 fails
% for a value, between/3 tries the next one automatically. When all values
% fail for a cell, the clause fails and Prolog backtracks to the previous
% choice point. No explicit stack is needed.
dfid(Board, _, Board) :-
    solved(Board).
dfid(Board, D, Solution) :-
    D > 0,
    nb_getval(dfid_nodes, N), N1 is N + 1, nb_setval(dfid_nodes, N1),
    next_empty(Board, Row, Col),
    between(1, 9, Value),
    valid_placement(Board, Row, Col, Value),
    place(Board, Row, Col, Value, NewBoard),
    D1 is D - 1,
    dfid(NewBoard, D1, Solution).

% solve_file(+Path, -Solution)
%
% Convenience predicate: loads a board from a text file, solves it, and
% prints the solution. All output is handled here so no extra calls are
% needed from the CLI goal.
%
% Example:
%   swipl -s src/prolog/dfid.pl \
%     -g "solve_file('data/input/classic_easy_01.txt', _), halt"
solve_file(Path, Solution) :-
    load_board(Path, Board),
    format("Puzzle:~n"),
    print_board(Board),
    nl,
    format("Solving...~n"),
    solve_dfid(Board, Solution),
    nl,
    format("Solution:~n"),
    print_board(Solution).
