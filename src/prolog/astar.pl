:- module(astar, [solve_astar/2, solve_file/2]).

:- use_module(sudoku).
:- use_module(library(heaps)).

% ── A* Solver ─────────────────────────────────────────────────────────────────
%
% Best-first search for Sudoku using f(n) = g(n) + h(n).
%
% g(n) = number of cells placed so far (depth from initial board).
% h(n) = number of empty cells remaining.
%        Admissible: each empty cell requires exactly one placement, so h
%        never overestimates the remaining cost.
%        Consistent: placing a cell decreases h by 1 and increases g by 1,
%        so f is non-decreasing along any path. This means the closed list
%        correctly prevents re-expansion.
%
% Note on f-value behaviour: because g + h = total_empty_initial (constant),
% all nodes at the same level share the same f-value. A* therefore expands
% levels in BFS order. The pruning power comes from valid_placement/4 (hard
% constraint checking) and MRV in next_empty/3, not from f-ordering.
% See report for analysis.
%
% Expansion strategy: for each node, pick the MRV empty cell (fewest valid
% candidates), try each candidate. States where any empty cell has zero
% candidates are silently dropped (dead ends).
%
% Open list: min-heap on f-value via library(heaps).
% Closed list: plain list of visited boards. For easy/medium puzzles this is
% fine; on expert puzzles A* will exhaust memory before DFID does.
%
% CLI usage (from project root):
%   swipl -s src/prolog/astar.pl \
%     -g "solve_file('data/input/classic_easy_01.txt', _), halt"

% ── Heuristic ─────────────────────────────────────────────────────────────────

% h(+Board, -H)
% H = number of empty cells (admissible, consistent).
h(Board, H) :-
    empty_cells(Board, Empties),
    length(Empties, H).

% ── Main entry point ──────────────────────────────────────────────────────────

% solve_astar(+Board, -Solution)
solve_astar(Board, Solution) :-
    nb_setval(astar_nodes, 0),
    get_time(Start),
    h(Board, H),
    singleton_heap(Open, H, state(Board, 0)),
    astar_loop(Open, [], Solution),
    get_time(End),
    nb_getval(astar_nodes, Nodes),
    Elapsed is End - Start,
    format("Nodes expanded : ~w~n", [Nodes]),
    format("Elapsed        : ~4f s~n", [Elapsed]).

% ── A* loop ───────────────────────────────────────────────────────────────────

% astar_loop(+Open, +Closed, -Solution)
%
% Extract the minimum-f node from the heap.
% If it is already in the closed list, skip it and recurse.
% If it is the goal, return it.
% Otherwise expand it, add successors to the heap, and recurse.
astar_loop(Open, Closed, Solution) :-
    get_from_heap(Open, _F, state(Board, G), Rest),
    (   member(Board, Closed)
    ->  astar_loop(Rest, Closed, Solution)
    ;   solved(Board)
    ->  Solution = Board
    ;   nb_getval(astar_nodes, N), N1 is N + 1, nb_setval(astar_nodes, N1),
        expand(Board, G, Rest, NewOpen),
        astar_loop(NewOpen, [Board|Closed], Solution)
    ).

% ── Expansion ─────────────────────────────────────────────────────────────────

% expand(+Board, +G, +OpenIn, -OpenOut)
%
% Pick the MRV empty cell; for each valid value generate a successor board,
% compute its f-value, and add it to the open heap.
% Boards where next_empty/3 finds a cell with zero candidates are skipped
% (they will fail next_empty because Pairs=[] in sudoku.pl's MRV).
expand(Board, G, OpenIn, OpenOut) :-
    (   next_empty(Board, Row, Col)
    ->  G1 is G + 1,
        findall(
            F1-state(NewBoard, G1),
            (   between(1, 9, Value),
                valid_placement(Board, Row, Col, Value),
                place(Board, Row, Col, Value, NewBoard),
                h(NewBoard, H1),
                F1 is G1 + H1
            ),
            Successors
        ),
        add_successors(OpenIn, Successors, OpenOut)
    ;   OpenOut = OpenIn   % no empty cell (shouldn't reach here; solved check above)
    ).

% add_successors(+HeapIn, +List, -HeapOut)
add_successors(Heap, [], Heap).
add_successors(HeapIn, [F-State|Rest], HeapOut) :-
    add_to_heap(HeapIn, F, State, HeapMid),
    add_successors(HeapMid, Rest, HeapOut).

% ── CLI convenience ───────────────────────────────────────────────────────────

% solve_file(+Path, -Solution)
solve_file(Path, Solution) :-
    load_board(Path, Board),
    format("Puzzle:~n"),
    print_board(Board),
    nl,
    format("Solving with A*...~n"),
    solve_astar(Board, Solution),
    nl,
    format("Solution:~n"),
    print_board(Solution).
