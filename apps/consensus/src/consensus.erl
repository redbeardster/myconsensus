-module(consensus).
-behaviour(gen_server).
-define(SERVER, ?MODULE).
-export([start_link/0]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-export([vote/0, propagate/2]).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

propagate(Node, Number) ->
  gen_server:cast(?SERVER, {propagate, Node, Number}).

vote() ->
  gen_server:cast(?SERVER, {vote, rand:uniform(1000)}).

init(Args) ->

    ets:new(nodelist, [set, named_table, public]),
    rand:seed(exs1024),

    {ok, Args}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({vote, Number}, State) ->

  io:format("Voting for node ~p with the value of ~p~n~n", [node(), Number]),
  ets:insert(nodelist, {node(), Number}),
  [rpc:cast(Node, consensus, propagate, [node(), Number]) || Node <- [node() | nodes()]],

  {noreply, State};

handle_cast({propagate, Node, Number}, State) ->

  io:format("Incoming vote for node ~p with the value of ~p~n~n", [Node, Number]),
  ets:insert(nodelist, {Node, Number}),

  case length(ets:match(nodelist, '$1')) - length([node() | nodes()]) of
     0 ->
            [{WinnerNode, Value}] = ets:match_object(nodelist, {'$1', lists:nth(1, lists:sort([Val || [{_Key, Val}] <- ets:match(nodelist, '$1')]))}),
            io:format("Winner node is ~p with the value: ~p~n~n", [WinnerNode, Value]),
            ets:delete_all_objects(nodelist);
      _ ->
            ok
  end,
  {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
