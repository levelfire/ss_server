%%%-------------------------------------------------------------------
%%% @author zqlt
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 一月 2015 下午5:27
%%%-------------------------------------------------------------------
-module(mod_ky_ms).
-author("zqlt").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-include("mod_ky.hrl").
-include("../../../../deps/file_log/include/file_log.hrl").

-define(SERVER, ?MODULE).

-define(WORK_PROC_SIZE, 50).
-define(MAX_ORDER_TIME, 1*60*60).

-export([
  order_work_func/0,
  generate_orders/3,
  read_public_key/0,
  complete_orders/7,
  query_order/2,
  read_src_public_key/0
]).

-record(state, {
  orders_work_pool,
  orders_work_pool_size,
  orders_init_value,
  orders_offset_value}).

%%%===================================================================
%%% API
%%%===================================================================
query_order(UserID, BillNo) ->
  gen_server:call(?MODULE, {query_order, {UserID, BillNo}}).

generate_orders(UserID, GoodsID, Uin) ->
  gen_server:call(?MODULE, {generate_orders, {UserID, GoodsID, Uin}}).

complete_orders(OrderID, BillNo, AccountID, Fee, ProductId, PayResult, Rationality) ->
  gen_server:call(?MODULE, {complete_orders, {AccountID, {OrderID, BillNo, AccountID, Fee, ProductId, PayResult, Rationality}}}).

read_public_key() ->
  gen_server:call(?MODULE, read_public_key).

read_src_public_key() ->
  gen_server:call(?MODULE, read_src_public_key).

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_link() ->
  {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
-spec(init(Args :: term()) ->
  {ok, State :: #state{}} | {ok, State :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term()} | ignore).
init([]) ->
  WorkPool = create_work_pool(?WORK_PROC_SIZE),
  {ok, #state{orders_work_pool = WorkPool, orders_work_pool_size = ?WORK_PROC_SIZE, orders_init_value = dd_util:to_list(dd_util:timestamp()), orders_offset_value = 0}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()},
    State :: #state{}) ->
  {reply, Reply :: term(), NewState :: #state{}} |
  {reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate} |
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), Reply :: term(), NewState :: #state{}} |
  {stop, Reason :: term(), NewState :: #state{}}).
handle_call({generate_orders, {UserID, GoodsID, Uin}}, From, #state{orders_work_pool = WorkPool, orders_work_pool_size = Size, orders_init_value = InitVal, orders_offset_value = OffSet} = State) ->
  BillNo = generate_bill_no(UserID, InitVal, OffSet),
  Pid = hash(UserID, WorkPool, Size),
  Pid ! {execute, From, {generate_orders, {BillNo, UserID, GoodsID, Uin}}},
  {noreply, State#state{orders_offset_value = OffSet + 1}};
handle_call(read_src_public_key, _From, State) ->
  Path = dd_util:to_list(os:getenv("KEY_DIR")) ++ "ky_key.key",
  PubKey = iolist_to_binary(get_public_key(Path)),
  Ret = {success, PubKey},
  {reply, Ret, State};
handle_call(read_public_key, _From, State) ->
  Ret =
    case dd_config:get_cfg(ky_public_key) of
      {success, Value} -> {success, Value};
      fail ->
        Path = dd_util:to_list(os:getenv("KEY_DIR")) ++ "ky_key.key",
        case read_pb_key(Path) of
          {success, Key} ->
            dd_config:write_cfg(ky_public_key, Key),
            {success, Key};
          fail -> fail
        end
    end,
  {reply, Ret, State};
handle_call({complete_orders, {AccountID, Value}}, From, #state{orders_work_pool = WorkPool, orders_work_pool_size = Size} = State) ->
  Pid = hash(AccountID, WorkPool, Size),
  Pid ! {execute, From, {complete_orders, Value}},
  {noreply, State};
handle_call({query_order, {UserID, BillNo}}, From, #state{orders_work_pool = WorkPool, orders_work_pool_size = Size} = State) ->
  Pid = hash(UserID, WorkPool, Size),
  Pid ! {execute, From, {query_order, BillNo}},
  {noreply, State};
handle_call(_Request, _From, State) ->
  {reply, ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_cast(Request :: term(), State :: #state{}) ->
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #state{}}).
handle_cast(_Request, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
-spec(handle_info(Info :: timeout() | term(), State :: #state{}) ->
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #state{}}).
handle_info(_Info, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
-spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
    State :: #state{}) -> term()).
terminate(_Reason, _State) ->
  ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
-spec(code_change(OldVsn :: term() | {down, term()}, State :: #state{},
    Extra :: term()) ->
  {ok, NewState :: #state{}} | {error, Reason :: term()}).
code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
create_work_pool(PoolCnt) ->
  lists:map(
    fun(_) ->
      spawn(?MODULE, order_work_func, [])
    end, lists:seq(1, PoolCnt)).

order_work_func() ->
  TableID = ets:new(order_ky, [set, protected, {keypos, #rd_order_ky.bill_no}]),
  order_work_func_1(TableID).

order_work_func_1(TableID) ->
  try
    receive
      {execute, From, {FuncName, Param}} ->
        Ret = mod_ky_ms_impl:execute(TableID, FuncName, Param),
        gen_server:reply(From, Ret),
        order_work_func_1(TableID);
      Other ->
        ?FILE_LOG_ERROR("order_work_func; error request = ~p", [Other]),
        order_work_func_1(TableID)
    after
      30*1000 ->
        CurTime = dd_util:timestamp() - ?MAX_ORDER_TIME,
        MatchSpec = [{#rd_order_ky{time_stamp = '$1', _='_'}, [{'=<', '$1', CurTime}], [true]}],
        DeleteCount = ets:select_delete(TableID, MatchSpec),
        if
          DeleteCount > 0 ->
            ?FILE_LOG_DEBUG("del expired orders count=~p", [DeleteCount]);
          true -> ok
        end,
        order_work_func_1(TableID)
    end
  catch
    What:Type ->
      ?FILE_LOG_ERROR("what = ~p, type =~p, stack = ~p", [What, Type, erlang:get_stacktrace()]),
      order_work_func_1(TableID)
  end.


generate_bill_no(UserID, InitVal, Offset) ->
  dd_util:to_list(UserID) ++ dd_util:to_list(InitVal) ++ dd_util:to_list(Offset).

hash(Id, WorkPool, Len) ->
  <<HashValue:128/unsigned-big-integer>> = erlang:md5(Id),
  lists:nth((HashValue rem Len) + 1,WorkPool).

read_pb_key(Path) ->
  try
    Key = iolist_to_binary(get_public_key(Path)),
    Spki = public_key:der_decode('SubjectPublicKeyInfo', base64:mime_decode(Key)),
    {_, _, {0, KeyDer}} = Spki,
    {success, public_key:der_decode('RSAPublicKey', KeyDer)}
  catch
    What:Type ->
      ?FILE_LOG_ERROR("read_pb_key error, what = ~p, type = ~p, stack = ~p", [What, Type, erlang:get_stacktrace()]),
      fail
  end.


get_public_key(KeyPath) ->
  {ok, FileBin} = file:read_file(KeyPath),
  public_key_lines(re:split(FileBin, "\n"), []).

public_key_lines([<<"-----BEGIN PUBLIC KEY-----">>|Rest], Acc) -> public_key_lines(Rest, Acc);
public_key_lines([<<"-----END PUBLIC KEY-----">>|_Rest], Acc) -> lists:reverse(Acc);
public_key_lines([Line|Rest], Acc) -> public_key_lines(Rest, [Line|Acc]).