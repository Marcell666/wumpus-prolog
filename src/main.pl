:- abolish(hunter/3).
:- abolish(wumpus/3).
:- abolish(pit/2).
:- abolish(gold/2).
:- abolish(grab/2).
:- abolish(actions/1).
:- abolish(visited/2).
:- abolish(runloop/1).

:- dynamic([
  hunter/3,
  wumpus/3,
  pit/2,
  gold/2,
  grab/2,
  actions/1,
  visited/2
]).

% Defines the world NxM matrix.
world(4, 4).

%     +---+---+---+---+
%   4 |   |   |   | P |
%     +---+---+---+---+
%   3 | W | G | P |   |
%     +---+---+---+---+
%   2 |   |   |   |   |
%     +---+---+---+---+
%   1 | H |   | P |   |
%     +---+---+---+---+
%       1   2   3   4
% Database.
% hunter(1, 1, east).
% wumpus(1, 3, alive).
% pit(3, 1).
% pit(3, 3).
% pit(4, 4).
% gold(2, 3).

% Test database
%     +---+---+---+---+
%   4 |   |   |   | G |
%     +---+---+---+---+
%   3 |   |   |   |   |
%     +---+---+---+---+
%   2 |   |   |   |   |
%     +---+---+---+---+
%   1 | H |   |   |   |
%     +---+---+---+---+
%       1   2   3   4
hunter(1, 1, east).
gold(4, 4).

visited(1, 1).

% ---------------------------- %
% Environment predicates       %
% ---------------------------- %
has_gold(yes) :- grab(X, Y), gold(X, Y), !.
has_gold(no).

has_arrows(yes) :- false.
has_arrows(no).

% Perceptions
% ===========
% If has gold it has glitter.
has_glitter(yes) :- has_gold(G), G == no, hunter(X, Y, _), gold(X, Y), !.
has_glitter(no).

% Senses breeze if adjacent block has a pit.
has_breeze(yes) :-
  hunter(X, Y, _), N is Y + 1, pit(X, N), !;
  hunter(X, Y, _), S is Y - 1, pit(X, S), !;
  hunter(X, Y, _), E is X + 1, pit(E, Y), !;
  hunter(X, Y, _), W is X - 1, pit(W, Y), !.
has_breeze(no).

% Senses stench if adjacent block has the wumpus.
has_stench(yes) :-
  hunter(X, Y, _), N is Y + 1, wumpus(X, N, _), !;
  hunter(X, Y, _), S is Y - 1, wumpus(X, S, _), !;
  hunter(X, Y, _), E is X + 1, wumpus(E, Y, _), !;
  hunter(X, Y, _), W is X - 1, wumpus(W, Y, _), !.
has_stench(no).

% Senses bump if is facing a wall
has_bump(yes) :-
  world(W, _), hunter(W, _, east),  !;
  world(_, H), hunter(_, H, north), !;
  hunter(1, _, west),  !;
  hunter(_, 1, south), !.
has_bump(no).

% Senses screm if wumpus have died
has_scream(yes) :- wumpus(_, _, S), S == dead, !.
has_scream(no).

% Check if player has died.
is_dead :-
  hunter(X, Y, _), wumpus(X, Y, _), !;
  hunter(X, Y, _), pit(X, Y), !.
is_alive :- \+ is_dead.

% Returns the current percetions
perceptions([Stench, Breeze, Glitter, Bump, Scream]) :-
  has_stench(Stench), has_breeze(Breeze), has_glitter(Glitter),
  has_bump(Bump), has_scream(Scream), !.

% Returns the angle given its direction.
direction(east,  0).
direction(north, 90).
direction(west,  180).
direction(south, 270).

% Check if position is into map bounds.
in_bounds(X, Y) :-
  world(W, H),
  X > 0, X =< W,
  Y > 0, Y =< H.

% Moves the Player to a new position.
move(X, Y) :-
  assertz(actions(move)),
  in_bounds(X, Y),
  format("- Moving to ~dx~d~n", [X,Y]),
  assertz( visited(X, Y) ),
  hunter(_, _, D),
  retractall( hunter(_, _, D) ), % Reset the hunter pos then reassign.
  asserta( hunter(X, Y, D) ),
  !.
move(X, Y) :- format('- Cannot move to ~dx~d~n', [X, Y]).

% Shoot at position and kill wumpus if its there
shoot(X, Y) :-
  assertz(actions(shoot)),
  has_arrows(yes),
  wumpus(X, Y, alive),
  retractall( wumpus(X, Y, alive) ),
  asserta( wumpus(X, Y, dead) ),
  !.
shoot(_, _) :- write('I don not have arrows anymore.').

% Get the position ahead of the player
next(X, Y) :- hunter(Xi, Yi, east),  X is Xi+1, Y is Yi, !.
next(X, Y) :- hunter(Xi, Yi, north), X is Xi, Y is Yi+1, !.
next(X, Y) :- hunter(Xi, Yi, west),  X is Xi-1, Y is Yi, !.
next(X, Y) :- hunter(Xi, Yi, south), X is Xi, Y is Yi-1, !.

% Get all neighbors
neighbors(L) :- findall(N, neighbor(N), L).
neighbor(B) :- hunter(X, Y, _), E is X+1, in_bounds(E, Y), B = [E, Y].
neighbor(B) :- hunter(X, Y, _), N is Y+1, in_bounds(X, N), B = [X, N].
neighbor(B) :- hunter(X, Y, _), W is X-1, in_bounds(W, Y), B = [W, Y].
neighbor(B) :- hunter(X, Y, _), S is Y-1, in_bounds(X, S), B = [X, S].

% Player's actions
action(grab) :-
  hunter(X, Y, _), assertz( grab(X, Y) ), \+ gold(X, Y),
  assertz(actions(grab)),
  write('- Nothing to grab'), nl.

action(grab) :-
  hunter(X, Y, _), assertz( grab(X, Y) ), has_gold(no), gold(X, Y),
  assertz(actions(grab)),
  write('- Found gold!'), nl.

action(turnleft) :-
  assertz(actions(turn)),
  write('- Turn left'), nl, assertz( actions(turn) ),
  hunter(X, Y, CD),
  direction(CD, A),
  Left is abs(A + 90) mod 360,
  direction(D, Left),
  retractall( hunter(_, _, _) ),
  asserta( hunter(X, Y, D) ).

action(turnright) :-
  assertz(actions(turn)),
  write('- Turn right'), nl, assertz( actions(turn) ),
  hunter(X, Y, CD),
  direction(CD, A),
  Right is abs(A - 90) mod 360,
  direction(D, Right),
  retractall( hunter(_, _, _) ),
  asserta( hunter(X, Y, D) ).

action(forward) :- next(X, Y), move(X, Y), !.
action(forward) :- next(X, Y), move(X, Y), !.
action(forward) :- next(X, Y), move(X, Y), !.
action(forward) :- next(X, Y), move(X, Y), !.

action(shoot) :- next(X, Y), shoot(X, Y), !.
action(shoot) :- next(X, Y), shoot(X, Y), !.
action(shoot) :- next(X, Y), shoot(X, Y), !.
action(shoot) :- next(X, Y), shoot(X, Y), !.

action(exit) :- write('- Bye, bye!'), nl, print_result, nl, halt.

% Apply a list of actions
action([]).
action([A|Actions]) :- action(A), action(Actions).

% ---------------------------- %
% Inferences rules             %
% ---------------------------- %
% Infer pit or wumpus if sensed an danger in two adjacents blocks.
is_dangerous(X, Y) :- has_pit(X, Y); has_wumpus(X, Y).

stench_at(-1, -1).
breeze_at(-1, -1).

has_pit(X, Y) :-
  E is X + 1, N is Y + 1, breeze_at(E, Y), breeze_at(X, N), !;
  N is Y + 1, W is X - 1, breeze_at(X, N), breeze_at(W, Y), !;
  W is X - 1, S is Y - 1, breeze_at(W, Y), breeze_at(X, S), !;
  S is Y - 1, E is X + 1, breeze_at(X, S), breeze_at(E, Y), !.

has_wumpus(X, Y) :-
  E is X + 1, N is Y + 1, stench_at(E, Y), stench_at(X, N), !;
  N is Y + 1, W is X - 1, stench_at(X, N), stench_at(W, Y), !;
  W is X - 1, S is Y - 1, stench_at(W, Y), stench_at(X, S), !;
  S is Y - 1, E is X + 1, stench_at(X, S), stench_at(E, Y), !.

% Score
score(S) :- findall(A, actions(A), As), length(As, S).

% Print
print_result :-
  score(S),
  format('~n~tResult~t~40|~n'),
  format('Score: ~`.t ~d~40|', [S]), nl,
  has_gold(yes) ->
    format('Outcome: ~`.t ~p~40|', [win]), nl;
    format('Outcome: ~`.t ~p~40|', [loose]), nl.

% Run the game
run :- runloop(0).

runloop(100) :- action(exit), !.
runloop(T) :-
  hunter(X, Y, D), perceptions(P),
  format('~d: At ~dx~d facing ~p, senses ~p. ', [T, X, Y, D, P]),
  heuristic(P, A),
  format('I\'m doing ~p.~n', [A]),
  action(A),
  % Iterate
  is_alive -> (
    Ti is T + 1,
    runloop(Ti)
  );
  write('- You have deceased'), nl,
  action(exit),
  !.