:- module(clpfd, [
                  op(760, yfx, #<==>),
                  op(750, xfy, #==>),
                  op(750, yfx, #<==),
                  op(740, yfx, #\/),
                  op(730, yfx, #\),
                  op(720, yfx, #/\),
                  op(710,  fy, #\),
                  op(700, xfx, #>),
                  op(700, xfx, #<),
                  op(700, xfx, #>=),
                  op(700, xfx, #=<),
                  op(700, xfx, #=),
                  op(700, xfx, #\=),
                  op(700, xfx, in),
                  op(700, xfx, ins),
                  op(450, xfx, ..), % should bind more tightly than \/
                  (#>)/2,
                  (#<)/2,
                  (#>=)/2,
                  (#=<)/2,
                  (#=)/2,
                  (#\=)/2,
                  (#<==>)/2,
                  (#==>)/2,
                  (#<==)/2,
                  (#\)/1,
                  (#\/)/2,
                  (#/\)/2,
                  in/2 ,
                  ins/2,
                  all_different/1,
                  all_distinct/1,
                  all_distinct/2,
		  maximize/1,
                  sum/3,
                  scalar_product/4, /*
                  tuples_in/2, */
                  labeling/2 /*,
                  label/1,
                  indomain/1,
                  lex_chain/1,
                  serialized/2,
                  global_cardinality/2,
                  global_cardinality/3,
                  circuit/1,
                  element/3,
                  automaton/3,
                  automaton/8,
                  transpose/2,
                  zcompare/3,
                  chain/2,
                  fd_var/1,
                  fd_inf/2,
                  fd_sup/2,
                  fd_size/2,
                  fd_dom/2 */
                 ]).

:- use_module(library(gecode)).
:- use_module(library(maplist)).

constraint( (_ #> _) ).
constraint( (_ #< _) ).
constraint( (_ #>= _) ).
constraint( (_ #=< _) ).
constraint( (_ #= _) ).
constraint( (_ #\= _) ).
constraint( (_ #\ _) ).
constraint( (_ #<==> _) ).
constraint( (_ #==> _) ).
constraint( (_ #<== _) ).
constraint( (_ #\/ _) ).
constraint( (_ #/\ _) ).
constraint( in(_, _) ). %2,
constraint( ins(_, _) ). %2,
constraint( all_different(_) ). %1,
constraint( all_distinct(_) ). %1,
constraint( all_distinct(_,_) ). %1,
constraint( sum(_, _, _) ). %3,
constraint( scalar_product(_, _, _, _) ). %4,
constraint( tuples_in(_, _) ). %2,
constraint( labeling(_, _) ). %2,
constraint( label(_) ). %1,
constraint( indomain(_) ). %1,
constraint( lex_chain(_) ). %1,
constraint( serialized(_, _) ). %2,
constraint( global_cardinality(_, _) ). %2,
constraint( global_cardinality(_, _, _) ). %3,
constraint( circuit(_) ). %1,
constraint( element(_, _, _) ). %3,
constraint( automaton(_, _, _) ). %3,
constraint( automaton(_, _, _, _, _, _, _, _) ). %8,
constraint( transpose(_, _) ). %2,
constraint( zcompare(_, _, _) ). %3,
constraint( chain(_, _) ). %2,
constraint( fd_var(_) ). %1,
constraint( fd_inf(_, _) ). %2,
constraint( fd_sup(_, _) ). %2,
constraint( fd_size(_, _) ). %2,
constraint( fd_dom(_, _) ). %2



process_constraints((B0,B1), (NB0, NB1), Env) :-
	process_constraints(B0, NB0, Env),
	process_constraints(B1, NB1, Env).
process_constraints(B, B, env(_Space)) :-
	constraint(B), !.
process_constraints(B, B, _Env).
%	process_constraint(B, NB, Space).

( A #= B) :-
	get_home(Env),
	post( rel(A,  (#=),  B), Env, _).
( A #\= B) :-
	get_home(Env),
	post( rel(A,  (#\=),  B), Env, _).
( A #< B) :-
	get_home(Env),
	post( rel(A,  (#<),  B), Env, _).
( A #> B) :-
	get_home(Env),
	post( rel(A,  (#>),  B), Env, _).
( A #=< B) :-
	get_home(Env),
	post( rel(A,  (#=<),  B), Env, _).
( A #>= B) :-
	get_home(Env),
	post( rel(A,  (#>=),  B), Env, _).
sum( L, Op, V) :-
	get_home( Env ),
	post( rel(sum(L), Op, V), Env, _).
( A #<==> VBool) :-
	get_home(Space-Map),
	Bool := boolvar(Space),
	m( VBool, Bool, 0, 1, Map),
	Space += reify(Bool, 'RM_EQV', R),
	post(A, Space-Map, R).
( A #==> VBool) :-
	get_home(Space-Map),
	Bool := boolvar(Space),
	m( VBool, Bool, 0, 1, Map),
	Space += reify(Bool, 'RM_IMP', R),
	post(A, Space-Map, R).
( A #<== VBool) :-
	get_home(Space-Map),
	Bool := boolvar(Space),
	m( VBool, Bool, 0, 1, Map),
	Space += reify(Bool, 'RM_PMI', R),
	post(A, Space-Map, R).
'#\\'(A) :-
	get_home(Space-Map),
	B := boolvar(Space),
	Space += reify(B, 'RM_EQV', R),
	Space += rel(B, 'BOT_EQV', 0),
	post(A, Space-Map, R).
( A1 #\/ A2 ) :-
	get_home(Space-Map),
	B1 := boolvar(Space),
	B2 := boolvar(Space),
	Space += reify(B1, 'RM_EQV', R1),
	Space += reify(B2, 'RM_EQV', R2),
	post(A1, Space-Map, R1),
	post(A2, Space-Map, R2),
	Space += rel(B1, B2, 'BOT_OR', 1).
( A1 #/\ A2 ) :-
	get_home(Space-Map),
	B1 := boolvar(Space),
	B2 := boolvar(Space),
	Space += reify(B1, 'RM_EQV', R1),
	Space += reify(B2, 'RM_EQV', R2),
	post(A1, Space-Map, R1),
	post(A2, Space-Map, R2),
	Space += rel(B1, B2, 'BOT_AND', 1).
( X in A..B) :-
	get_home(Space-Map),
	m(X, NX, A, B, Map),
	NX := intvar(Space, A, B).
( Xs ins A..B) :-
	get_home(Space-Map),
	maplist(lm(A, B, Map), Xs, NXs),
	length(Xs, N),
	NXs := intvars(Space, N, A, B).
all_different( Xs ) :-
	get_home(Env),
	post( all_different( Xs ), Env, _ ).
all_distinct( Xs ) :-
	get_home(Env),
	post( all_distinct( Xs ), Env, _ ).
all_distinct( Cs, Xs ) :-
	get_home(Env),
	post( all_distinct( Cs, Xs ), Env, _ ).
scalar_product( Cs, Vs, Rels, X ) :-
	get_home(Env),
	post( scalar_product( Cs, Vs, Rels, X ), Env, _ ).

labeling(_Opts, Xs) :-
	get_home(Space-Map),
	maplist(ll(Map), Xs, NXs),
	Space += branch(NXs, 'INT_VAR_SIZE_MIN', 'INT_VAL_MIN').

maximize(V) :-
	get_home(Space-Map),
	l(V, I, Map),
	Space += maximize(I).

post( ( A #= B), Env, Reify) :-
	post( rel( A, (#=), B), Env, Reify).
post( ( A #\= B), Env, Reify) :-
	post( rel( A, (#\=), B), Env, Reify).
post( ( A #> B), Env, Reify) :-
	post( rel( A, (#>), B), Env, Reify).
post( ( A #< B), Env, Reify) :-
	post( rel( A, (#<), B), Env, Reify).
post( ( A #>= B), Env, Reify) :-
	post( rel( A, (#>=), B), Env, Reify).
post( ( A #=< B), Env, Reify) :-
	post( rel( A, (#=<), B), Env, Reify).
% X #< Y 
% X #< 2
post( rel( A, Op, B), Space-Map, Reify):-
	var(A),
	( var(B) -> l(B, IB, Map) ; integer(B) -> IB = B ), !,
	l(A, IA, Map),
	gecode_arith_op( Op, GOP ),
	(var(Reify) ->	Space += rel(IA, GOP, IB) ;
	    Space += rel(IA, GOP, IB, Reify) ).
% 2 #\= B
post( rel( A, Op, B), Space-Map, Reify):-
	var(B), integer(A), !,
	l(B, IB, Map),
	gecode_arith_op( Op, GOP ),
	(var(Reify) ->	Space += rel(A, GOP, IB) ;
	    Space += rel(A, GOP, IB, Reify) ).
% sum([A,B,C]) #= X
post( rel( sum(L), Op, Out), Space-Map, Reify):-
	checklist( var, L ), 
	( var(Out) -> l(Out, IOut, Map) ; integer(Out) -> IOut = Out ), !,
	var(Out), !,
	maplist(ll(Map), [Out|L], [IOut|IL] ),
	gecode_arith_op( Op, GOP ),
	(var(Reify) ->
	    Space += linear(IL, GOP, IOut);
	 Space += linear(IL, GOP, IOut, Reify)
	).
% [A,B,C,D] #< 3
post( rel( A, Op, B), Space-Map, Reify):-
	checklist( var, A ), 
	( var(B) -> l(B, IB, Map) ; integer(B) -> IB = B ), !,
	maplist(ll(Map), A, IL ),
	gecode_arith_op( Op, GOP ),
	(var(Reify) ->	Space += rel(IL, GOP, IB) ;
	    Space += rel(IL, GOP, IB, Reify) ).
post( rel(A, Op, B), Space-Map, Reify):-
	( nonvar(A), ( A = _+_ ; A = _-_ ) ; 
	  nonvar(B), ( B = _ + _ ; B = _-_) ), !,
	linearize(A, 1, As, Bs, CAs, CBs, 0, A0, Space-Map),
	linearize(B, -1, Bs, [], CBs, [], A0, B0, Space-Map),
	gecode_arith_op( Op, GOP ),
	(var(Reify) ->
	    ( checklist(is_one, CAs) ->
		Space += linear(As, GOP, B0);
		Space += linear(CAs, As, GOP, B0) 
	    )
	    ;
	    ( checklist(is_one, CAs) ->
		Space += linear(As, GOP, B0, Reify);
		Space += linear(CAs, As, GOP, B0, Reify) 
	    )
	).
post( rel(A, Op, B), Space-Map, Reify):-
	nonvar(A),
	arith(A, Name),
	A =.. [_Op,A1], !, 
	equality(A1, NA1,  Space-Map),
	in_c(NA1, VA1,  Space-Map), !,
	equality(B, B1,  Space-Map),
	out_c(Name, VA1, B1,  Op, Space-Map, Reify).
post( rel(A, Op, B), Space-Map, Reify):-
	nonvar(A),
	arith(A, Name),
	A =.. [_Op,A1,A2], !, 
	equality(A1, NA1,  Space-Map),
	in_c(NA1, VA1,  Space-Map),
	equality(A2, NA2,  Space-Map),
	in_c(NA2, VA2,  Space-Map),
	equality(B, B1,  Space-Map),
	out_c(Name, VA1, VA2, B1,  Op, Space-Map, Reify).
post( scalar_product(Cs, L, Op, Out), Space-Map, Reify):-
	var(Out), !,
	maplist(ll(Map), [Out|L], [IOut|IL] ),
	gecode_arith_op( Op, GOP ),
	(var(Reify) ->
	    Space += linear(Cs, IL, GOP, IOut);
	    Space += linear(Cs, IL, GOP, IOut, Reify)
	).
post( scalar_product(Cs, L, Op, Out), Space-Map, Reify):-
	integer(Out), !,
	maplist(ll(Map), L, IL ),
	gecode_arith_op( Op, GOP ),
	(var(Reify) ->
	    Space += linear(Cs, IL, GOP, Out);
	    Space += linear(Cs, IL, GOP, Out, Reify)
	).
post( all_different( Xs ), Space-Map, Reify) :-
	maplist(ll(Map), Xs, NXs),
	(var(Reify) ->
	    Space += distinct(NXs)
	;
	    throw(error(domain(not_reifiable),all_different( Xs )))
	).
post( all_distinct( Xs ), Space-Map, Reify) :-
	maplist(ll(Map), Xs, NXs),
	(var(Reify) ->
	    Space += distinct(NXs)
	;
	    throw(error(domain(not_reifiable),all_distinct( Xs )))
	).
post( all_distinct( Cs , Xs ), Space-Map, Reify) :-
	maplist(ll(Map), Xs, NXs),
	(var(Reify) ->
	    Space += distinct(Cs,NXs)
	;
	    throw(error(domain(not_reifiable),all_distinct( Cs , Xs )))
	).

gecode_arith_op( (#=) , 'IRT_EQ' ).
gecode_arith_op( (#\=) , 'IRT_NQ' ).
gecode_arith_op( (#>) , 'IRT_GE' ).
gecode_arith_op( (#>=) , 'IRT_GQ' ).
gecode_arith_op( (#<) , 'IRT_LE' ).
gecode_arith_op( (#=<) , 'IRT_LQ' ).

linearize(V, C, [A|As], As, [C|CAs], CAs, I, I, _-Map) :- 
	var(V), !,
	l(V, A, Map).
linearize(A+B, C, As, Bs, CAs, CBs, I, IF, Env) :-
	linearize(A, C, As, A1s, CAs, CA1s, I, I1, Env),
	linearize(B, C, A1s, Bs, CA1s, CBs, I1, IF, Env).
linearize(A-B, C, As, Bs, CAs, CBs, I, IF, Env) :-
	NC is -C,
	linearize(A, C, As, A1s, CAs, CA1s, I, I1, Env),
	linearize(B, NC, A1s, Bs, CA1s, CBs, I1, IF, Env).
linearize(A, C, As, As, CAs, CAs, I, IF, _) :-
	integer(A), !,
	IF is I-C*A.
linearize(A, C, As, As, CAs, CAs, I, IF, _) :-
	ground(A),
	catch( (B is eval(A)), _, fail ), !,
	IF is I-C*B.
linearize(C1*B, C, As, Bs, CAs, CBs, I, IF, Env) :-
	integer(C1), !,
	NC is C*C1,
	linearize(B, NC, As, Bs, CAs, CBs, I, IF, Env).
linearize(B*C1, C, As, Bs, CAs, CBs, I, IF, Env) :-
	integer(C1), !,
	NC is C*C1,
	linearize(B, NC, As, Bs, CAs, CBs, I, IF, Env).
linearize(AC, C, [A|Bs], Bs, [C|CBs], CBs, I, I, Env) :-
	arith(AC, _),
	equality(AC, V, Env),
	Env = _-Map,
	l(V, A, Map).

arith(abs(_), abs).
arith(min(_,_), min).
arith(max(_,_), max).
arith((_ * _), times).
arith((_ / _), div).
arith((_ mod _), mod).

% replace abs(min(A,B)-max(A,B)) by
%    min(A,B,A1), max(A,B,A2), linear([1,-1],[A1,B1],=,A3), abs(A3,AN)
equality(V, V, _Env) :-
	var( V ), !.
equality(V, V, _Env) :-
	integer( V ), !.
equality(abs(V), NV, Env) :-
	equality(V, VA, Env),
	new_arith(abs, VA, NV, Env).
equality(V1+V2, NV, Env) :-
	equality(V1, V1A, Env),
	equality(V2, V2A, Env),
	new_arith( plus, V1A, V2A, NV, Env).
equality(V1-V2, NV, Env) :-
	equality(V1, V1A, Env),
	equality(V2, V2A, Env),
	new_arith( minus, V1A, V2A, NV, Env).
equality(V1*V2, NV, Env) :-
	equality(V1, V1A, Env),
	equality(V2, V2A, Env),
	new_arith( times, V1A, V2A, NV, Env).
equality(V1/V2, NV, Env) :-
	equality(V1, V1A, Env),
	equality(V2, V2A, Env),
	new_arith( div, V1A, V2A, NV, Env).
equality(V1 mod V2, NV, Env) :-
	equality(V1, V1A, Env),
	equality(V2, V2A, Env),
	new_arith( (mod), V1A, V2A, NV, Env).
equality(max( V1 , V2), NV, Env) :-
	equality(V1, V1A, Env),
	equality(V2, V2A, Env),
	new_arith( (max), V1A, V2A, NV, Env).
equality(min( V1 , V2), NV, Env) :-
	equality(V1, V1A, Env),
	equality(V2, V2A, Env),
	new_arith( (min), V1A, V2A, NV, Env).

% abs(X) #= 3
out_c(Name, A1, B,  Op, Space-Map, Reify) :-
	integer(B), !,
	new_arith( Name, A1, NB, Space-Map),
	gecode_arith_op( Op, BOP ),
	l(NB, IB, Map),
	( var(Reify) -> 
	    Space += rel(IB, BOP, B)
	;
	    Space += rel(IB, BOP, B, Reify)
	).
% abs(X) #= Cin[..]
out_c(Name, A1, B,  (#=), Space-Map, Reify) :-
	var(Reify),
	l(B, IB, Map), !,
	l(A1, IA1, Map),
	G =.. [Name, IA1, IB],
	Space += G.
% abs(X) #= NEW
out_c(Name, A1, B,  (#=), Space-Map, Reify) :-
	var(Reify), !,
	new_arith( Name, A1, B, Space-Map).
% abs(X) #> NEW
out_c(Name, A1, B,  Op, Space-Map, Reify) :-
	l(B, IB0, Map), !,
	new_arith( Name, A1, NB, Space-Map),
	l(NB, IB, Map),
	gecode_arith_op( Op, BOP ),
	(
	    nonvar(Reify) ->
	    Space += rel(IB, BOP, IB0)
	;
	    Space += rel(IB, BOP, IB0, Reify)
	).

% X*Y #= 3
out_c(Name, A1, A2, B, Op, Space-Map, Reify) :-
	integer(B), !,
	new_arith( Name, A1, A2, NB, Space-Map),
	l(NB, IB, Map),
	gecode_arith_op( Op, BOP ),
	( var(Reify) -> 
	    Space += rel(IB, BOP, B)
	;
	    Space += rel(IB, BOP, B, Reify)
	).
% X*Y #= Cin[..]
out_c(Name, A1, A2, B,  (#=), Space-Map, Reify) :-
	var(Reify),
	l(B, IB, Map), !,
	l(A1, IA1, Map),
	l(A2, IA2, Map),
	G =.. [Name, IA1, IA2, IB],
	Space += G.
% abs(X) #= NEW, cannot be reified
out_c(Name, A1, A2, B,  (#=), Space-Map, Reify) :-
	var(Reify), !,
	new_arith( Name, A1, A2, B, Space-Map).
% min(X,Y) #= Cin[..] <=>
out_c(Name, A1, A2, B,  Space-Map, Reify) :-
	l(B, IB0, Map), !,
	new_arith( Name, A1, A2, NB, Space-Map),
	l(NB, IB, Map),
	gecode_arith_op( Op, BOP ),
	( var(Reify) ->
	    Space += rel(IB, BOP, IB0)
	;
	    Space += rel(IB, BOP, IB0, Reify)
	).

new_arith( abs, V, NV, Space-Map) :-
	l(V, X, Min0, Max0, Map),
	( Min0 < 0 ->
	    ( Max0 < 0 -> Min is -Max0, Max is -Min0 ;
		Min = 0 , Max is max( -Min0, Max0 ) )
	    ;
	    Min = Min0, Max = Max0
	),
	NX := intvar(Space, Min, Max),
	m(NV, NX, Min, Max, Map),
	Space += abs(X, NX).

new_arith( minus, V1, V2, NV, Space-Map) :-
	l(V1, X1, Min1, Max1, Map),
	l(V2, X2, Min2, Max2, Map),
	Min is Min1-Max2,
	Max is Max1-Min2,
	NX := intvar(Space, Min, Max),
	m(NV, NX, Min, Max, Map),
	Space += linear([1,-1], [X1,X2], 'IRT_EQ', NX).

new_arith( plua, V1, V2, NV, Space-Map) :-
	l(V1, X1, Min1, Max1, Map),
	l(V2, X2, Min2, Max2, Map),
	Min is Min1+Min2,
	Max is Max1+Max2,
	NX := intvar(Space, Min, Max),
	m(NV, NX, Min, Max, Map),
	Space += linear([1,1], [X1,X2], 'IRT_EQ', NX).

new_arith( min, V1, V2, NV, Space-Map) :-
	l(V1, X1, Min1, Max1, Map),
	l(V2, X2, Min2, Max2, Map),
	Min is min(Min1,Min2),
	Max is min(Max1,Max2),
	NX := intvar(Space, Min, Max),
	m(NV, NX, Min, Max, Map),
	Space += min(X1, X2, NX).

new_arith( max, V1, V2, NV, Space-Map) :-
	l(V1, X1, Min1, Max1, Map),
	l(V2, X2, Min2, Max2, Map),
	Min is max(Min1,Min2),
	Max is max(Max1,Max2),
	NX := intvar(Space, Min, Max),
	m(NV, NX, Min, Max, Map),
	Space += max(X1, X2, NX).

new_arith( times, V1, V2, NV, Space-Map) :-
	l(V1, X1, Min1, Max1, Map),
	l(V2, X2, Min2, Max2, Map),
	min_times(Min1,Min2,Max1,Max2,Min),
	max_times(Min1,Min2,Max1,Max2,Max),
	NX := intvar(Space, Min, Max),
	m(NV, NX, Min, Max, Map),
	Space += times(X1, X2, NX).

new_arith( (div), V1, V2, NV, Space-Map) :-
	l(V1, X1, Min1, Max1, Map),
	l(V2, X2, Min2, Max2, Map),
	min_div(Min1,Min2,Max1,Max2,Min),
	max_div(Min1,Min2,Max1,Max2,Max),
	NX := intvar(Space, Min, Max),
	m(NV, NX, Min, Max, Map),
	Space += div(X1, X2, NX).

new_arith( (mod), V1, V2, NV, Space-Map) :-
	l(V1, X1, _Min1, Max1, Map),
	l(V2, X2, Min2, Max2, Map),
	Min is 0,
	Max is min(abs(Max1), Max2-1),
	NX := intvar(Space, Min, Max),
	m(NV, NX, Min, Max, Map),
	Space += mod(X1, X2, NX).


min_times(Min1,Min2,Max1,Max2,Min) :-
	Min is min(Min1*Min2, min(Min1*Max2, min(Max1*Min2, Max1*Max2))).

max_times(Min1,Min2,Max1,Max2,Max) :-
	Max is max(Min1*Min2, max(Min1*Max2, max(Max1*Min2, Max1*Max2))).

min_div(Min1,Min20,Max1,Max20,Min) :-
	( Min20 == 0 -> Min2 = 1 ; Min2 = Min20),
	( Max20 == 0 -> Max2 = -1; Max2 = Max20),
	Min is min(Min1 div Min2, min(Min1 div Max2, min(Max1 div Min2, Max1 div Max2))).

max_div(Min1,Min20,Max1,Max20,Max) :-
	( Min20 == 0 -> Min2 = 1 ; Min2 = Min20),
	( Max20 == 0 -> Max2 = -1; Max2 = Max20),
	Max is max(Min1 div Min2, max(Min1 div Max2, max(Max1 div Min2, Max1 div Max2))).

in_c(A, A,  _y) :-
	var(A), !.
in_c(C, A, Space-Map) :-
	integer(C), 
	Min is C-1,
	NX := intvar(Space, Min, C),
	m(A, NX, Min, C, Map),
	Space += rel(NX, 'IRT_EQ', C).

user:term_expansion( ( H :- B), (H :- (clpfd:init_gecode(Space, Me), NB, clpfd:close_gecode(Space, Vs, Me)) ) ) :-
	process_constraints(B, NB, Env),
	term_variables(H, Vs),
	nonvar( Env ), !,
	Env = env( Space ).

init_gecode(Space, old) :-
	nb_current(gecode_space, Space), nonvar(Space), !.
init_gecode(Space-Map, new) :-
	Space := space,
	b_setval(gecode_space, Space-Map).

close_gecode(_Space, _Vs, old) :- !.
close_gecode(Space-Map, Vs0, new) :- 
	term_variables(Vs0, Vs),
	selectlist(intvar(Map), Vs, CVs),
	maplist(ll(Map), CVs, IVs),
	SolSpace := search(Space),
	CVs := val(SolSpace,IVs).

intvar(Map, V) :-
	l(V, _IV, Map).

get_home(Home) :-
	b_getval(gecode_space, Home).

m(NV, OV, NA, NB, Vs) :-
	var(Vs), !,
	Vs = [v(NV,OV,NA,NB)|_].
m(NV, OV, NA, NB, [_|Vs]) :-
	m(NV, OV, NA, NB, Vs).

lm(A, B, Map, X, Y) :-
	m(X, Y, A, B, Map).

l(NV, OV, Vs) :-
	var(Vs), !,
	fail.
l(NV, OV, [v(V, OV, _A, _B)|_Vs]) :-
	V == NV, !.
l(NV, OV, [_|Vs]) :-
	l(NV, OV, Vs).

ll(Map, X, Y) :-
	l(X, Y, Map).

l(NV, OV, _, _, Vs) :-
	var(Vs), !,
	fail.
l(NV, OV, A, B, [v(V, OV, A, B)|_Vs]) :-
	V == NV, !.
l(NV, OV, A, B, [_|Vs]) :-
	l(NV, OV, A, B, Vs).

is_one(1).

