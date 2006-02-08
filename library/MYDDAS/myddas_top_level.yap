/*************************************************************************
*									 *
*	 YAP Prolog 							 *
*									 *
*	Yap Prolog was developed at NCCUP - Universidade do Porto	 *
*									 *
* Copyright L.Damas, V.S.Costa and Universidade do Porto 1985-1997	 *
*									 *
**************************************************************************
*									 *
* File:		myddas_top_level.yap	                                 *
* Last rev:							         *
* mods:									 *
* comments:	MYDDAS Top Level predicates		                 *
*									 *
*************************************************************************/

:- module(myddas_top_level,[
			    db_top_level/5,
			    db_datalog_select/3
			   ]).

:- use_module(myddas_mysql,[
			    db_my_result_set/1
			    ]).

:- use_module(charsio,[
		       read_from_chars/2
		      ]).

:- use_module(terms,[
		     term_variables/2
		    ]).

:- use_module(myddas_util_predicates,[
				      '$make_list_of_args'/4,
				      '$prolog2sql'/3,
				      '$write_or_not'/1,
				      '$lenght'/2
				     ]).
				     
db_top_level(mysql,Connection,_,_,_):-
	%'$error_checks'(db_open(mysql,Connection,Host/Db,User,Password)),
	get_value(Connection,Con),
	Con \= [],!,
	c_db_connection_type(Con,mysql),
	db_my_result_set(Mode),
	c_db_tl_top_level_mysql(Con,Mode).

db_top_level(datalog,Connection,_,_,_):-
	%'$error_checks'(db_open(mysql,Connection,Host/Db,User,Password)),
	get_value(Connection,Con),
	Con \= [],!,
	c_db_connection_type(Con,mysql),
	Prompt = ' datalog> ',
	nl,
	'$top_level_datalog_cicle'(Connection,Prompt).
% 	c_db_tl_readline(Prompt,Line),
% 	name(Line,CharsLine),
% 	read_from_chars(CharsLine,Query),
% 	term_variables(Query,VarList),
% 	db_datalog_select(Connection,VarList,Query).

'$top_level_datalog_cicle'(Connection,Prompt):-
	c_db_tl_readline(Prompt,Line),
	name(Line,CharsLine),
	catch(read_from_chars(CharsLine,Query),_,'$top_level_datalog_cicle'(Connection,Prompt)),
	!,'$top_level_datalog'(Connection,Prompt,Query).


'$top_level_datalog'(_,_,halt):-!.
'$top_level_datalog'(Connection,Prompt,Query):-
	term_variables(Query,[]),!,
	Query =..[_|Args],
	db_datalog_select(Connection,Args,Query),
	'$top_level_datalog_cicle'(Connection,Prompt).
'$top_level_datalog'(Connection,Prompt,Query):-
	term_variables(Query,VarList),
	db_datalog_select(Connection,VarList,Query),
	!,'$top_level_datalog_cicle'(Connection,Prompt).
	
db_datalog_select(Connection,LA,DbGoal):-
	
	'$lenght'(LA,Arity),
	functor(ViewName,viewname,Arity),
	% build arg list for viewname/Arity
	'$make_list_of_args'(1,Arity,ViewName,LA),
	
	'$prolog2sql'(ViewName,DbGoal,SQL),
	
	get_value(Connection,Con),
	c_db_connection_type(Con,ConType),
	'$write_or_not'(SQL),
	%( ConType == mysql ->
	db_my_result_set(Mode),
	c_db_my_query(SQL,ResultSet,Con,Mode),
	c_db_my_table_write(ResultSet).
	



	

% db_top_level(mysqlConnection,Host/Db,User,Password):-
% 	%'$error_checks'(db_open(mysql,Connection,Host/Db,User,Password)),
% 	c_db_my_connect(Host,User,Password,Db,Con),
% 	set_value(Connection,Con),
% 	db_my_result_set(Mode),
% 	c_db_top_level(Con,Mode).
