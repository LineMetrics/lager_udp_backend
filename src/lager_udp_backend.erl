%% Copyright (c) 2013 by LineMetrics Gmbh. All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.

-module(lager_udp_backend).
-behaviour(gen_event).

-export([
   init/1,
   handle_call/2,
   handle_event/2,
   handle_info/2,
   terminate/2,
   code_change/3,
   test/0
]).

-record(state, {
   host,
   port,
   socket,
   level
}).

%% socket options for upd socket
-define(SOCKET_OPTIONS, [binary, {active, false}, {reuseaddr, true}]).

init(Params) ->
   Host = config_val(host, Params, "localhost"),
   Port = config_val(port, Params, 5599),
   Level = config_val(level, Params, debug),

   %% open udp socket
   {ok, Socket} = gen_udp:open(Port, ?SOCKET_OPTIONS),

   {ok, #state{
      host = Host,
      port = Port,
      socket = Socket,
      level = Level
   }}.

handle_call({set_loglevel, Level}, #state{} = State) ->
   {ok, ok, State#state{level = lager_util:level_to_num(Level)}};

handle_call(get_loglevel, #state{level = Level} = State) ->
   {ok, Level, State};

handle_call(_Request, State) ->
   {ok, ok, State}.

handle_event({log, Msg}, #state{level=LogLevel} = State) ->
   {Date, Time} = lager_msg:datetime(Msg),
   case lager_util:is_loggable(Msg, LogLevel, ?MODULE) of
      true ->
         {ok, log(lager_msg:severity_as_int(Msg), Date, Time, Msg, State)};

      _ ->
         {ok, State}
   end;
handle_event({log, {lager_msg, [], Dest, Level, {Date, Time}, Message}} = M, #state{level = L} = State) when Level > L ->
   {ok, log(Level, Date, Time, Message, State)};
handle_event({log, Level, {Date, Time}, Message}, #state{level = L} = State) when Level =< L ->
   {ok, log(Level, Date, Time, Message, State)};
handle_event(_Event, State) ->
   {ok, State}.

handle_info(_Info, State) ->
   {ok, State}.

terminate(_Reason, State) ->
   gen_tcp:close(State#state.socket),
   ok.

code_change(_OldVsn, State, _Extra) ->
   {ok, State}.

%%%%%
log(Level, DateTime, Time, Message, #state{socket = Socket} = State) ->
%%    io:format("log: ~p~n",[Message]),
%%    [_LevelString, [Pid|_W], M] = Message,
   StringLevel = atom_to_list(lager_util:num_to_level(Level)),

   Meta = [iolist_to_binary([atom_to_list(K), "=", make_printable(V)]) || {K,V} <- lager_msg:metadata(Message)],

   Msg = {[{<<"time">>, list_to_binary([DateTime, " " , Time])}, {<<"lev">>, list_to_binary(StringLevel)},
      {<<"meta">>, Meta},
      {<<"msg">>,list_to_binary(lager_msg:message(Message))}]}, 
   send(State, msgpack:pack(Msg)).

send(#state{socket = Socket} = State, Message) ->
   case gen_udp:send(Socket, State#state.host, State#state.port, Message) of
      ok                ->    NewState = State;
      {error, closed}   ->   {ok, NewSocket} = gen_udp:open(State#state.port, ?SOCKET_OPTIONS),
                              gen_udp:send(NewSocket, State#state.host, State#state.port, Message),
                              NewState = State#state{socket = NewSocket}
   end,
   NewState.

config_val(C, Params, Default) ->
   case lists:keyfind(C, 1, Params) of
      {C, V} -> V;
      _ -> Default
   end.

make_printable(A) when is_list(A) -> A;
make_printable(A) when is_atom(A) -> atom_to_list(A);
make_printable(P) when is_pid(P) -> pid_to_list(P);
make_printable(Other) -> io_lib:format("~p",[Other]).


test() ->
   application:load(lager),
   application:set_env(lager, handlers, [{lager_console_backend, debug}, {lager_udp_backend, []}]),
   application:set_env(lager, error_logger_redirect, false),
   application:start(lager),
   lager:log(info, self(), "Test INFO message"),
   lager:log(debug, self(), "Test DEBUG message"),
   lager:log(error, self(), "Test ERROR message").
  
