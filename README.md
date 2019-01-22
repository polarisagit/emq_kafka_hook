
emq-plugin-template
===================

EMQ broker plugin to catch broker hooks through redis.<br>
[http://emqtt.io](http://emqtt.io)<br>

## Build Plugin

Add the plugin into emq-relx [v2.3.11](https://github.com/emqx/emqx-rel/tree/v2.3.11) ：

Makefile：

```
DEPS += emq_kafka_hook 

dep_emq_redis_hook  = git https://github.com/polarisagit/emq_kafka_hook v2.3.11
```

relx.config：

```
{emq_kafka_hook, load} 
```

## emq_kafka_hook.conf

```
[
  {emq_kafka_hook, [
        {kafka, [
                %kafka settings,{ip1,port1},{ip2,port2},{ip3,port3}
                { bootstrap_broker, [{"192.168.15.115", 9092}] },
                { query_api_versions, false },
                { reconnect_cool_down_seconds, 10}
                ]
        },
        {settings, [
                %kafka topic,default emq_broker_message
                { emq_hook_topic, "emq_broker_message"},
                %kafka topic key,default messageKEY
                { emq_hook_topic_key, "messageKEY"},
                %kafka topic partitions num,default 1
                { num_partitions, 1}
                ]
        }
  ]}
].
```



## data:

- client.connected

```json
{
    "action":"client_connected",
    "client_id":"client_id",
    "username":"username",
    "conn_ack":0,
    "ts":1548126301262
}
```

- client.disconnected

```json
{
    "action":"client_disconnected",
    "client_id":"client_id",
    "username":"username",
    "reason":"normal",
    "ts":1548126301262
}
```

- client.subscribe

```json
{
    "action":"client_subscribe",
    "client_id":"client_id",
    "username":"username",
    "topic":"bench/1",
    "opts":{
        "qos":0
    },
    "ts":1548126301262
}
```

- client.unsubscribe

```json
{
    "action":"client_unsubscribe",
    "client_id":"client_id",
    "username":"username",
    "topic":"bench/1",
    "ts":1548126301262
}
```

- session.created

```json
{
    "action":"session_created",
    "client_id":"client_id",
    "username":"username",
    "ts":1548126301262
}
```

- session.subscribed

```json
{
    "action":"session_subscribed",
    "client_id":"client_id",
    "username":"username",
    "topic":"bench/1",
    "opts":{
        "qos":0
    },
    "ts":1548126301262
}
```

- session.unsubscribed

```json
{
    "action":"session_unsubscribed",
    "client_id":"client_id",
    "username":"username",
    "topic":"bench/1",
    "ts":1548126301262
}
```

- session.terminated

```json
{
    "action":"session_terminated",
    "client_id":"client_id",
    "username":"username",
    "reason":"normal",
    "ts":1548126301262
}
```

- message.publish

```json
{
    "action":"message_publish",
    "from_client_id":"client_id",
    "from_username":"username",
    "topic":"bench/1",
    "qos":0,
    "retain":true,
    "payload":"Hello world!",
    "ts":1548126301262
}
```

- message.delivered

```json
{
    "action":"message_delivered",
    "client_id":"client_id",
    "username":"username",
    "from_client_id":"client_id_from",
    "from_username":"username_from",
    "topic":"bench/1",
    "qos":0,
    "retain":true,
    "payload":"Hello world!",
    "ts":1548126301262
}
```

- message.acked

```json
{
    "action":"message_acked",
    "client_id":"client_id",
    "username":"username",
    "from_client_id":"client_id_from",
    "from_username":"username_from",
    "topic":"bench/1",
    "qos":1,
    "retain":true,
    "payload":"Hello world!",
    "ts":1548126301262
}
```



Plugin and Hooks
-----------------

[Plugin Design](http://docs.emqtt.com/en/latest/design.html#plugin-design)

[Hooks Design](http://docs.emqtt.com/en/latest/design.html#hooks-design)

License
-------

Apache License Version 2.0
