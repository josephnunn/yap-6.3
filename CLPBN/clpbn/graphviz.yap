:- module(gviz, [clpbn2gviz/4]).

clpbn2gviz(Stream, Name, Network, Output) :-
	format(Stream, 'digraph ~w {
	graph [ rankdir="LR" ];~n',[Name]),
	output_vars(Stream, Network),
	info_ouput(Stream, Output),
	format(Stream, '}~n',[]).

output_vars(_, []).
output_vars(Stream, [V|Vs]) :-
	output_var(Stream, V),
	output_vars(Stream, Vs).

output_var(Stream, V) :-
	clpbn:get_atts(V,[key(Key),evidence(_)]),
	output_key(Stream,Key),
	format(Stream, ' [ shape=box, style=filled, fillcolor=red, fontsize=18.0  ]~n',[]),
	fail.
output_var(Stream, V) :-
	clpbn:get_atts(V,[key(Key),dist(DInfo)]),
	extract_parents(DInfo,Parents),
	Parents = [_|_], !,
	format(Stream, '	',[]),
	output_parents(Stream, Parents),
	format(' -> ',[]),
	output_key(Stream,Key),
	nl(Stream).
output_var(_, _).

info_ouput(_, []).
info_ouput(Stream, [V|Output]) :-
	clpbn:get_atts(V,[key(Key)]),
	output_key(Stream,Key),
	format(Stream, ' [ shape=box, style=filled, fillcolor=green, fontsize=18.0 ]~n',[]),
	info_ouput(Stream, Output).


output_parents(Stream, [V]) :- !,
	clpbn:get_atts(V,[key(Key)]),
	output_key(Stream,Key).
output_parents(Stream, L) :-
	format(Stream,'{ ',[]),
	output_parents1(Stream,L),
	format(Stream,'}',[]).

output_parents1(_,[]).
output_parents1(Stream,[V|L]) :-
	clpbn:get_atts(V,[key(Key)]),
	output_key(Stream,Key),
	put_code(Stream, 0' ),
	output_parents1(Stream,L).


extract_parents(tab(_,_),[]).
extract_parents(tab(_,_,Parents),Parents).	
extract_parents((sum.Parents->_),Parents) :- !.
extract_parents((normalised_average(_).Parents->_),Parents) :- !.
extract_parents(([_|_].Parents->_),Parents) :- !.
extract_parents((_->_),[]).

output_key(Stream, Key) :-
	output_key(Stream, 0, Key).

output_key(Stream, _, Key) :-
	primitive(Key), !,
	write(Stream, Key).
output_key(Stream, I0, Key) :-
	Key =.. [Name|Args],
	write(Stream, Name),
	I is I0+1,
	output_key_args(Stream, I, Args).

output_key_args(_, _, []).
output_key_args(Stream, I, [Arg|Args]) :-
	format(Stream, '~*c', [I,0'_]),
	output_key(Stream, I, Arg),
	output_key_args(Stream, I, Args).

