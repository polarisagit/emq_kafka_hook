%%--------------------------------------------------------------------
%% Copyright (c) 2013-2018 EMQ Enterprise, Inc. (http://emqtt.io)
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(emq_kafka_hook).

-include_lib("emqttd/include/emqttd.hrl").

-include_lib("brod/include/brod_int.hrl").

-define(EMQ_HOOK_TOPIC, "emq_broker_message").
  

-define(EMQ_HOOK_TOPIC_KEY, "messageKey").

-define(NUM_PARTITIONS, 1).

-export([load/1, unload/0]).

%% Hooks functions

-export([on_client_connected/3, on_client_disconnected/3]).

-export([on_client_subscribe/4, on_client_unsubscribe/4]).

-export([on_session_created/3, on_session_subscribed/4, on_session_unsubscribed/4, on_session_terminated/4]).

-export([on_message_publish/2, on_message_delivered/4, on_message_acked/4]).

-define(LOG(Level, Format, Args), lager:Level("Kafka Hook: " ++ Format, Args)).

-define(EMPTY(S), (S == <<"">> orelse S == undefined)).
 
load(Env) ->
    brod_init([Env]),
    emqttd:hook('client.connected', fun ?MODULE:on_client_connected/3, [Env]),
    emqttd:hook('client.disconnected', fun ?MODULE:on_client_disconnected/3, [Env]),
    emqttd:hook('client.subscribe', fun ?MODULE:on_client_subscribe/4, [Env]),
    emqttd:hook('client.unsubscribe', fun ?MODULE:on_client_unsubscribe/4, [Env]),
    emqttd:hook('session.created', fun ?MODULE:on_session_created/3, [Env]),
    emqttd:hook('session.subscribed', fun ?MODULE:on_session_subscribed/4, [Env]),
    emqttd:hook('session.unsubscribed', fun ?MODULE:on_session_unsubscribed/4, [Env]),
    emqttd:hook('session.terminated', fun ?MODULE:on_session_terminated/4, [Env]),
    emqttd:hook('message.publish', fun ?MODULE:on_message_publish/2, [Env]),
    emqttd:hook('message.delivered', fun ?MODULE:on_message_delivered/4, [Env]),
    emqttd:hook('message.acked', fun ?MODULE:on_message_acked/4, [Env]).

on_client_connected(ConnAck, Client = #mqtt_client{client_id = ClientId, username = Username}, _Env) ->
    %?LOG(debug, "on_client_connected: ~p ~p", [ClientId, ConnAck]),
    Params = [{action, client_connected},
              {client_id, ClientId},
              {username, Username},
              {conn_ack, ConnAck},
              {ts, emqttd_time:now_ms()}],
    send_kafka_request(Params),
    {ok, Client}.

on_client_disconnected(Reason, _Client = #mqtt_client{client_id = ClientId, username = Username}, _Env) 
    %?LOG(debug, "on_client_disconnected: ~p ~p", [ClientId, Reason]),
    when is_atom(Reason) ->
    Params = [{action, client_disconnected},
              {client_id, ClientId},
              {username, Username},
              {reason, Reason},
              {ts, emqttd_time:now_ms()}],
    send_kafka_request(Params),
    ok;
on_client_disconnected(Reason, _Client, _Env) ->
    ?LOG(error, "Client disconnected, cannot encode reason: ~p", [Reason]),
    ok.

on_client_subscribe(ClientId, Username, TopicTable, _Env) ->
    %?LOG(debug, "on_client_subscribe: ~p ~p ~p", [ClientId, Username, TopicTable]),
    %{ok, TopicTable}.
    lists:foreach(fun({Topic, Opts}) ->
            Params = [{action, client_subscribe},
                      {client_id, ClientId},
                      {username, Username},
                      {topic, Topic},
                      {opts, Opts},
                      {ts, emqttd_time:now_ms()}],
            send_kafka_request(Params)
    end, TopicTable).
    
on_client_unsubscribe(ClientId, Username, TopicTable, _Env) ->
    %?LOG(debug, "on_client_unsubscribe: ~p ~p ~p", [ClientId, Username, TopicTable]),
    %{ok, TopicTable}.
    lists:foreach(fun({Topic, Opts}) ->
            Params = [{action, client_unsubscribe},
                      {client_id, ClientId},
                      {username, Username},
                      {topic, Topic},
                      {opts, Opts},
                      {ts, emqttd_time:now_ms()}],
            send_kafka_request(Params)
    end, TopicTable).

on_session_created(ClientId, Username, _Env) ->
    %?LOG(debug, "on_session_created: ~p ~p", [ClientId, Username]),
    Params = [{action, session_created},
              {client_id, ClientId},
              {username, Username},
              {ts, emqttd_time:now_ms()}],
    send_kafka_request(Params),
    ok.

on_session_subscribed(ClientId, Username, {Topic, Opts}, _Env) ->
    %?LOG(debug, "on_session_subscribed: ~p ~p", [ClientId, Username]),
    Params = [{action, session_subscribed},
              {client_id, ClientId},
              {username, Username},
              {topic, Topic},
              {opts, Opts},
              {ts, emqttd_time:now_ms()}],
    send_kafka_request(Params),
    {ok, {Topic, Opts}}.

on_session_unsubscribed(ClientId, Username, {Topic, Opts}, _Env) ->
    %?LOG(debug, "on_session_unsubscribed: ~p ~p ~p ~p", [ClientId, Username, Topic, Opts]),
    Params = [{action, session_unsubscribed},
              {client_id, ClientId},
              {username, Username},
              {topic, Topic},
              {ts, emqttd_time:now_ms()}],
    send_kafka_request(Params),
    ok.

on_session_terminated(ClientId, Username, Reason, _Env) ->
    %?LOG(debug, "on_session_terminated: ~p ~p ~p ", [ClientId, Username, Reason]),
    Params = [{action, session_terminated},
              {client_id, ClientId},
              {username, Username},
              {reason, Reason},
              {ts, emqttd_time:now_ms()}],
    send_kafka_request(Params),
    ok.

on_message_publish(Message = #mqtt_message{topic = <<"$SYS/", _/binary>>}, _Env) ->
    {ok, Message};
on_message_publish(Message, _Env) ->
     Params = [{action, message_publish},
                  {from_client_id, c(Message#mqtt_message.from)},
                  {from_username, u(Message#mqtt_message.from)},
                  {topic, Message#mqtt_message.topic},
                  {qos, Message#mqtt_message.qos},
                  {retain, Message#mqtt_message.retain},
                  {payload, Message#mqtt_message.payload},
                  {ts, emqttd_time:now_ms(Message#mqtt_message.timestamp)}],
     send_kafka_request(Params),
     {ok, Message}.

on_message_delivered(ClientId, Username, Message, _Env) ->
    %?LOG(debug, "on_message_delivered: ~p ~p ~p", [ClientId, Username, Message]),
    Params = [{action, message_delivered},
                  {client_id, ClientId},
                  {username, Username},
                  {from_client_id, c(Message#mqtt_message.from)},
                  {from_username, u(Message#mqtt_message.from)},
                  {topic, Message#mqtt_message.topic},
                  {qos, Message#mqtt_message.qos},
                  {retain, Message#mqtt_message.retain},
                  {payload, Message#mqtt_message.payload},
                  {ts, emqttd_time:now_ms(Message#mqtt_message.timestamp)}],
    send_kafka_request(Params),
    {ok, Message}.

on_message_acked(ClientId, Username, Message, _Env) ->
    %?LOG(debug, "on_message_acked: ~p ~p ~p", [ClientId, Username, Message]),
    Params = [{action, message_acked},
                  {client_id, ClientId},
                  {username, Username},
                  {from_client_id, c(Message#mqtt_message.from)},
                  {from_username, u(Message#mqtt_message.from)},
                  {topic, Message#mqtt_message.topic},
                  {qos, Message#mqtt_message.qos},
                  {retain, Message#mqtt_message.retain},
                  {payload, Message#mqtt_message.payload},
                  {ts, emqttd_time:now_ms(Message#mqtt_message.timestamp)}],
    send_kafka_request(Params),
    {ok, Message}.

%% Called when the plugin application stop
unload() ->
    application:stop(brod),
    emqttd:unhook('client.connected', fun ?MODULE:on_client_connected/3),
    emqttd:unhook('client.disconnected', fun ?MODULE:on_client_disconnected/3),
    emqttd:unhook('client.subscribe', fun ?MODULE:on_client_subscribe/4),
    emqttd:unhook('client.unsubscribe', fun ?MODULE:on_client_unsubscribe/4),
    emqttd:unhook('session.created', fun ?MODULE:on_session_created/3),
    emqttd:unhook('session.subscribed', fun ?MODULE:on_session_subscribed/4),
    emqttd:unhook('session.unsubscribed', fun ?MODULE:on_session_unsubscribed/4),
    emqttd:unhook('session.terminated', fun ?MODULE:on_session_terminated/4),
    emqttd:unhook('message.publish', fun ?MODULE:on_message_publish/2),
    emqttd:unhook('message.delivered', fun ?MODULE:on_message_delivered/4),
    emqttd:unhook('message.acked', fun ?MODULE:on_message_acked/4).

%%--------------------------------------------------------------------
%% Internal functions
%%--------------------------------------------------------------------

send_kafka_request(Params) ->
    %?LOG(debug, "Params: ~p ", [Params]),
    Json = jsx:encode(Params),
    Partition = getPartition(""),
    %?LOG(debug, " Partition: ~p ", [Partition]),
    {ok, EmqHookTopic}=application:get_env(?MODULE, emq_hook_topic),
    {ok, EmqHookTopicValue}=application:get_env(?MODULE, emq_hook_topic_value),

    {ok, CallRef} = brod:produce(brod_client_1, EmqHookTopic, Partition, EmqHookTopicValue, Json),
    receive
        #brod_produce_reply{ call_ref = CallRef,
                             result   = brod_produce_req_acked
                }->
        ok
    after 5000 ->
        ?LOG(error, "send_kafka_request timeout!~p",["5000"])
    end.

brod_init(_Env) ->
    {ok, _} = application:ensure_all_started(brod),
    {ok, Kafka} = application:get_env(?MODULE, kafka),
    {ok, Settings} = application:get_env(?MODULE, settings),
    %?LOG(debug, "brod_init Settings: ~p ",  [Settings]),
    KafkaBootstrapEndpoints = proplists:get_value(bootstrap_broker, Kafka),
    %?LOG(debug, "brod_init kafkabootstrapendpoints: ~p ",  [KafkaBootstrapEndpoints]),
    
    EmqHookTopic = list_to_binary(proplists:get_value(emq_hook_topic, Settings, ?EMQ_HOOK_TOPIC)),
    %?LOG(debug, "brod_init Emq_hook_topic: ~p ",  [EmqHookTopic]),
    application:set_env(?MODULE, emq_hook_topic, EmqHookTopic),
    application:set_env(?MODULE, emq_hook_topic_key, 
			list_to_binary(proplists:get_value(emq_hook_topic_key, Settings, ?EMQ_HOOK_TOPIC_KEY))),
    application:set_env(?MODULE, num_partitions,
                        proplists:get_value(num_partitions, Settings, ?NUM_PARTITIONS)), 

    ok = brod:start_client(KafkaBootstrapEndpoints, brod_client_1),
    ok = brod:start_producer(brod_client_1, EmqHookTopic, _ProducerConfig = []).


c({ClientId, _}) -> ClientId;
c(From) -> From.
u({_, Username}) -> Username;
u(From) -> From.

getPartition(Key) when ?EMPTY(Key) ->
    {ok, Num} = application:get_env(?MODULE, num_partitions),
    %?LOG(debug, "getPartiton Num: ~p ",  [application:get_env(?MODULE, num_partitions)]),
    %crypto:rand_uniform(0, ?NUM_PARTITIONS);
    rand:uniform(Num)-1;
getPartition(Key) ->
    <<_, _, _, _, _,
      _, _, _, _, _,
      _, _, _, _, _,
      NodeD16>> = crypto:hash(md5, Key),
    {ok, Num} = application:get_env(?MODULE, num_partitions),
    NodeD16 rem Num.
