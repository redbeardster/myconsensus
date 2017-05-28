-module(consensus_sup).
-behaviour(supervisor).
-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).


init([]) ->

	Server = {consensus, {consensus, start_link, []},
                        permanent, 2000, worker, [consensus]},

    {ok, { {one_for_one, 5, 10}, [Server]} }.
