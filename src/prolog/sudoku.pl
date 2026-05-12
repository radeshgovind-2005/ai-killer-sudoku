:- module(sudoku, [
    board_size/1,
    board_length/1,
    empty_board/1,
    valid_board/1,
    board_from_rows/2,
    board_from_string/2,
    load_board/2,
    cell/4,
    set_cell/5,
    row/3,
    column/3,
    box_index/3,
    box_cells/3,
    print_board/1
]).

:- use_module(library(readutil)).

board_size(9).

board_length(Length) :-
    board_size(Size),
    Length is Size * Size.

empty_board(Board) :-
    board_length(Length),
    length(Board, Length),
    maplist(=(0), Board).

valid_board(Board) :-
    board_length(Length),
    length(Board, Length),
    maplist(valid_cell_value, Board).

valid_cell_value(Value) :-
    integer(Value),
    between(0, 9, Value).

board_from_rows(Rows, Board) :-
    board_size(Size),
    length(Rows, Size),
    maplist(same_length_(Size), Rows),
    append(Rows, Board),
    valid_board(Board).

same_length_(Size, Row) :-
    length(Row, Size).

board_from_string(Input, Board) :-
    string_codes(Input, Codes),
    include(relevant_board_code, Codes, RelevantCodes),
    maplist(code_to_cell, RelevantCodes, Board),
    valid_board(Board).

relevant_board_code(Code) :-
    code_type(Code, digit).
relevant_board_code(0'.).

code_to_cell(0'., 0).
code_to_cell(Code, Value) :-
    code_type(Code, digit),
    Value is Code - 0'0.

load_board(Path, Board) :-
    read_file_to_string(Path, Contents, []),
    board_from_string(Contents, Board).

cell(Board, Row, Col, Value) :-
    valid_coordinate(Row),
    valid_coordinate(Col),
    Index is (Row - 1) * 9 + (Col - 1),
    nth0(Index, Board, Value).

set_cell(Board, Row, Col, Value, NewBoard) :-
    valid_board(Board),
    valid_coordinate(Row),
    valid_coordinate(Col),
    valid_cell_value(Value),
    Index is (Row - 1) * 9 + (Col - 1),
    same_length(Board, NewBoard),
    nth0(Index, Board, _, Rest),
    nth0(Index, NewBoard, Value, Rest).

row(Board, RowNumber, Row) :-
    valid_board(Board),
    valid_coordinate(RowNumber),
    StartIndex is (RowNumber - 1) * 9,
    length(Prefix, StartIndex),
    append(Prefix, Suffix, Board),
    length(Row, 9),
    append(Row, _, Suffix).

column(Board, ColNumber, Column) :-
    valid_board(Board),
    valid_coordinate(ColNumber),
    findall(Value, cell(Board, _, ColNumber, Value), Column).

box_index(Row, Col, BoxIndex) :-
    valid_coordinate(Row),
    valid_coordinate(Col),
    BoxRow is (Row - 1) // 3,
    BoxCol is (Col - 1) // 3,
    BoxIndex is BoxRow * 3 + BoxCol.

box_cells(Board, BoxIndex, Values) :-
    valid_board(Board),
    between(0, 8, BoxIndex),
    StartRow is (BoxIndex // 3) * 3 + 1,
    StartCol is (BoxIndex mod 3) * 3 + 1,
    findall(
        Value,
        (
            between(0, 2, RowOffset),
            between(0, 2, ColOffset),
            Row is StartRow + RowOffset,
            Col is StartCol + ColOffset,
            cell(Board, Row, Col, Value)
        ),
        Values
    ).

print_board(Board) :-
    valid_board(Board),
    forall(
        between(1, 9, RowNumber),
        (
            row(Board, RowNumber, Row),
            print_row(Row)
        )
    ).

print_row(Row) :-
    maplist(display_value, Row, DisplayValues),
    atomic_list_concat(DisplayValues, ' ', Line),
    writeln(Line).

display_value(0, '.').
display_value(Value, Value).

valid_coordinate(Value) :-
    between(1, 9, Value).
