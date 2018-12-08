-module(ring).
-export([run_test/2, set_up_node/2]).

run_test(Node_count, Turns) ->
	io:format("Setting up ~p nodes for ~p rounds...~n", [Node_count, Turns]),
	Node = spawn(?MODULE, set_up_node, [self(), Node_count]),
	receive
		hey_ho_lets_go -> 
			Duration = start_test(Node, Turns),
			io:format("Running ~p rounds with ~p nodes took ~p seconds~n", [Turns, Node_count, Duration/1000])

	end.

get_timestamp() ->
	{Mega, Sec, Micro} = os:timestamp(),
	(Mega*1000000 + Sec)*1000 + round(Micro/1000).

start_test(Node, Turns) ->
	Start = get_timestamp(),
	io:format("starting test at ~p", [Start]),
	End = start_round(Node, Turns),
	End - Start.


start_round(Node, 0) ->
	End = get_timestamp(),
	io:format("~n==========~nwe're done.~nit is ~p~nstoping them all~n", [End]),
	Node ! stop_buddy,
	receive 
		stop_buddy -> 
			io:format("that's all folks~n"),
			End
	end;
start_round(Node, Turns) ->
	Node ! {round, Turns},
	io:format("~n==========~nstarted round ~p~n", [Turns]),
	receive
		{round, Turns} -> 
			io:format("round ~p done~n", [Turns]),
			start_round(Node, Turns-1)
	end.


set_up_node(Start_node, 1) ->
	io:format("i am ze last node~n"),
	Start_node ! hey_ho_lets_go,
	run_node(Start_node, 1);

set_up_node(Start_node, Counter) ->
	Follower = spawn(?MODULE, set_up_node, [Start_node, Counter-1]),
	run_node(Follower, Counter).

run_node(Follower, Counter) ->
	receive
		stop_buddy -> 
			Follower ! stop_buddy,
			io:format("node ~p says bye~n", [Counter]);
		{round, Turn} ->
			Follower ! {round, Turn},
			io:format("node ~p sent turn signal ~p on . . .~n", [Counter, Turn]),
			run_node(Follower, Counter)
			
	end.
