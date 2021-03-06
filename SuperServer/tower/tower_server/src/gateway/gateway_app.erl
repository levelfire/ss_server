-module(gateway_app).
-author('erlangonrails@gmail.com').
-behaviour(application).
-include("../../deps/file_log/include/file_log.hrl").
-include("gateway.hrl").

-export([start/2, 
         stop/1,
         prep_stop/1]).

-spec start(Type :: term(), StartArgs :: term()) -> 
    {ok, pid()} | {error, 'badarg'}.
start(normal, _StartArgs) ->
    dd_ctl:write_pid_file(),
    ok = dd_util:ensure_app_started(sasl),
    ok = dd_util:ensure_app_started(crypto),
    ok = dd_util:ensure_app_started(file_log),
  ok = dd_util:ensure_app_started(hash_service),
    ok = dd_util:ensure_app_started(public_key),
    ok = dd_util:ensure_app_started(mnesia),
    ok = dd_util:ensure_app_started(ssl),
    ok = dd_util:ensure_app_started(inets),

    wait_mnesia_table(),

    {ok, _} = dd_config:start_link(os:getenv("GATEWAY_CFG_PATH")),
    {ok, Pid} = gateway_sup:start_link(),

  master:notify_node_up(),
    log_running_applications(),
    ?FILE_LOG_INFO("gateway ~s is started in the node ~p", [?GATEWAY_VERSION, node()]),
    {ok, Pid};
start(_Type, _StartArgs) ->
    {error, 'badarg'}.

wait_mnesia_table() ->
  mnesia:wait_for_tables([global_config], infinity).

prep_stop(State) ->
    State.

stop(_State) ->
    dd_ctl:delete_pid_file(),
  master:notify_node_down(),
    ?FILE_LOG_INFO("gateway ~s is stopped in the node ~p", [?GATEWAY_VERSION, node()]),
    ok.
    
-spec log_running_applications() ->
    ok.
log_running_applications() ->
    lists:foreach(
      fun(App) ->
          ?FILE_LOG_INFO("running application#~p", [App])
      end, application:which_applications()).

