:- module(killer_sudoku, [
    valid_cage/2,
    partial_cage_ok/2,
    valid_cages/2,
    partial_cages_ok/2,
    solve_dfid_killer/3,
    solve_astar_killer/3,
    killer_puzzle/3,
    solve_killer_file/2
]).

:- use_module(sudoku).
:- use_module(library(heaps)).
:- use_module(library(lists)).

% ── Killer Sudoku Extension ───────────────────────────────────────────────────
%
% Adds cage constraints on top of standard Sudoku rules.
%
% A cage is the term: cage(TargetSum, [(R1,C1),(R2,C2),...])
%   - All cells in a cage must sum to TargetSum
%   - All values within a cage must be unique (no repeats)
%   - Standard Sudoku constraints (row/col/box) still apply
%
% Two levels of cage checking:
%   valid_cage/2       — full check: all cells filled, sum + uniqueness correct
%   partial_cage_ok/2  — pruning check during search:
%                          * filled values are unique
%                          * current sum does not exceed target
%                          * remaining empty cells can still reach target
%
% The partial check fires after every placement, allowing early pruning of
% branches that cannot satisfy a cage regardless of future placements.
%
% CLI usage (from project root):
%   swipl -s src/prolog/killer_sudoku.pl \
%     -g "solve_killer_file(easy_01, _), halt"

% ── Cell value helper ─────────────────────────────────────────────────────────

cell_value(Board, (R, C), V) :-
    cell(Board, R, C, V).

% ── Full cage validation ──────────────────────────────────────────────────────

% valid_cage(+Board, +cage(Sum, Cells))
% True when all cage cells are filled, their sum equals Sum, and all
% values are distinct. Called on the complete solution to verify correctness.
valid_cage(Board, cage(Sum, Cells)) :-
    maplist(cell_value(Board), Cells, Values),
    \+ member(0, Values),
    sum_list(Values, Sum),
    all_different(Values).

% valid_cages(+Board, +Cages)
valid_cages(Board, Cages) :-
    maplist(valid_cage(Board), Cages).

% ── Partial cage pruning ──────────────────────────────────────────────────────

% partial_cage_ok(+Board, +cage(Sum, Cells))
% Pruning predicate used during search (before the cage is fully filled).
% Succeeds unless the current partial assignment is provably incompatible.
%
% Checks:
%   1. Filled values are distinct (no cage-internal repeat).
%   2. Current sum of filled values does not exceed TargetSum.
%   3. Minimum achievable total (current + 1 per empty cell) <= TargetSum.
%   4. Maximum achievable total (current + 9 per empty cell) >= TargetSum.
%
% Using 1 as min and 9 as max per remaining cell is intentionally conservative
% (both are loose bounds). This ensures no valid branch is incorrectly pruned.
partial_cage_ok(Board, cage(Sum, Cells)) :-
    maplist(cell_value(Board), Cells, Values),
    exclude(=(0), Values, Filled),
    all_different(Filled),
    sum_list(Filled, CurrentSum),
    CurrentSum =< Sum,
    length(Values, TotalCells),
    length(Filled, FilledCount),
    Remaining is TotalCells - FilledCount,
    MinTotal is CurrentSum + Remaining,      % lower bound: all remaining = 1
    MinTotal =< Sum,
    MaxTotal is CurrentSum + Remaining * 9,  % upper bound: all remaining = 9
    MaxTotal >= Sum.

% partial_cages_ok(+Board, +Cages)
partial_cages_ok(Board, Cages) :-
    maplist(partial_cage_ok(Board), Cages).

% ── DFID with cage constraints ────────────────────────────────────────────────

% solve_dfid_killer(+Board, +Cages, -Solution)
solve_dfid_killer(Board, Cages, Solution) :-
    nb_setval(dfid_k_nodes, 0),
    get_time(Start),
    empty_cells(Board, Empties),
    length(Empties, N),
    between(N, 81, Depth),
    dfid_killer(Board, Cages, Depth, Solution), !,
    get_time(End),
    nb_getval(dfid_k_nodes, Nodes),
    Elapsed is End - Start,
    format("Nodes expanded : ~w~n", [Nodes]),
    format("Elapsed        : ~4f s~n", [Elapsed]).

% dfid_killer(+Board, +Cages, +Depth, -Solution)
dfid_killer(Board, Cages, _, Board) :-
    solved(Board),
    valid_cages(Board, Cages).
dfid_killer(Board, Cages, D, Solution) :-
    D > 0,
    nb_getval(dfid_k_nodes, N), N1 is N + 1, nb_setval(dfid_k_nodes, N1),
    next_empty(Board, Row, Col),
    between(1, 9, Value),
    valid_placement(Board, Row, Col, Value),
    place(Board, Row, Col, Value, NewBoard),
    partial_cages_ok(NewBoard, Cages),
    D1 is D - 1,
    dfid_killer(NewBoard, Cages, D1, Solution).

% ── A* with cage constraints ──────────────────────────────────────────────────

% solve_astar_killer(+Board, +Cages, -Solution)
solve_astar_killer(Board, Cages, Solution) :-
    nb_setval(astar_k_nodes, 0),
    get_time(Start),
    empty_cells(Board, Empties),
    length(Empties, H),
    singleton_heap(Open, H, state(Board, 0)),
    astar_killer_loop(Open, [], Cages, Solution),
    get_time(End),
    nb_getval(astar_k_nodes, Nodes),
    Elapsed is End - Start,
    format("Nodes expanded : ~w~n", [Nodes]),
    format("Elapsed        : ~4f s~n", [Elapsed]).

% astar_killer_loop(+Open, +Closed, +Cages, -Solution)
astar_killer_loop(Open, Closed, Cages, Solution) :-
    get_from_heap(Open, _F, state(Board, G), Rest),
    (   member(Board, Closed)
    ->  astar_killer_loop(Rest, Closed, Cages, Solution)
    ;   solved(Board), valid_cages(Board, Cages)
    ->  Solution = Board
    ;   nb_getval(astar_k_nodes, N), N1 is N + 1, nb_setval(astar_k_nodes, N1),
        expand_killer(Board, G, Cages, Rest, NewOpen),
        astar_killer_loop(NewOpen, [Board|Closed], Cages, Solution)
    ).

% expand_killer(+Board, +G, +Cages, +OpenIn, -OpenOut)
expand_killer(Board, G, Cages, OpenIn, OpenOut) :-
    (   next_empty(Board, Row, Col)
    ->  G1 is G + 1,
        findall(
            F1-state(NewBoard, G1),
            (   between(1, 9, Value),
                valid_placement(Board, Row, Col, Value),
                place(Board, Row, Col, Value, NewBoard),
                partial_cages_ok(NewBoard, Cages),
                empty_cells(NewBoard, Es),
                length(Es, H1),
                F1 is G1 + H1
            ),
            Successors
        ),
        add_successors_k(OpenIn, Successors, OpenOut)
    ;   OpenOut = OpenIn
    ).

add_successors_k(Heap, [], Heap).
add_successors_k(HeapIn, [F-State|Rest], HeapOut) :-
    add_to_heap(HeapIn, F, State, HeapMid),
    add_successors_k(HeapMid, Rest, HeapOut).

% ── Hardcoded killer puzzles ──────────────────────────────────────────────────

% killer_puzzle(+Name, -Board, -Cages)
%
% Puzzle easy_01: hybrid killer — starts from the classic_easy_01 given cells
% (the Wikipedia Sudoku) so uniqueness is guaranteed and solving is fast.
% 27 three-cell row-group cages are added on top of the standard constraints.
% All cage sums are derived from the known solution (534678912 / 672195348 / ...).
killer_puzzle(easy_01, Board, Cages) :-
    board_from_string("530070000600195000098000060800060003400803001700020006060000280000419005000080079", Board),
    Cages = [
        cage(12, [(1,1),(1,2),(1,3)]),
        cage(21, [(1,4),(1,5),(1,6)]),
        cage(12, [(1,7),(1,8),(1,9)]),
        cage(15, [(2,1),(2,2),(2,3)]),
        cage(15, [(2,4),(2,5),(2,6)]),
        cage(15, [(2,7),(2,8),(2,9)]),
        cage(18, [(3,1),(3,2),(3,3)]),
        cage(9,  [(3,4),(3,5),(3,6)]),
        cage(18, [(3,7),(3,8),(3,9)]),
        cage(22, [(4,1),(4,2),(4,3)]),
        cage(14, [(4,4),(4,5),(4,6)]),
        cage(9,  [(4,7),(4,8),(4,9)]),
        cage(12, [(5,1),(5,2),(5,3)]),
        cage(16, [(5,4),(5,5),(5,6)]),
        cage(17, [(5,7),(5,8),(5,9)]),
        cage(11, [(6,1),(6,2),(6,3)]),
        cage(15, [(6,4),(6,5),(6,6)]),
        cage(19, [(6,7),(6,8),(6,9)]),
        cage(16, [(7,1),(7,2),(7,3)]),
        cage(15, [(7,4),(7,5),(7,6)]),
        cage(14, [(7,7),(7,8),(7,9)]),
        cage(17, [(8,1),(8,2),(8,3)]),
        cage(14, [(8,4),(8,5),(8,6)]),
        cage(14, [(8,7),(8,8),(8,9)]),
        cage(12, [(9,1),(9,2),(9,3)]),
        cage(16, [(9,4),(9,5),(9,6)]),
        cage(17, [(9,7),(9,8),(9,9)])
    ].

% ── CLI convenience ───────────────────────────────────────────────────────────

% solve_killer_file(+PuzzleName, -Solution)
% Solves a named killer puzzle with both DFID and A*, printing results.
solve_killer_file(Name, Solution) :-
    killer_puzzle(Name, Board, Cages),
    format("Killer puzzle: ~w~n~n", [Name]),
    format("Solving with DFID...~n"),
    solve_dfid_killer(Board, Cages, Solution),
    nl,
    format("Solution (DFID):~n"),
    print_board(Solution),
    nl,
    format("Solving with A*...~n"),
    solve_astar_killer(Board, Cages, Solution2),
    nl,
    format("Solution (A*):~n"),
    print_board(Solution2).
