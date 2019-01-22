PROJECT = emq_kafka_hook
PROJECT_DESCRIPTION = EMQ Kafka Hook
PROJECT_VERSION = 2.3.11

DEPS = brod
dep_brod = git https://github.com/klarna/brod  v3.7.3


BUILD_DEPS = emqttd cuttlefish
dep_emqttd = git https://github.com/emqtt/emqttd v2.3.11
dep_cuttlefish = git https://github.com/emqtt/cuttlefish v2.0.11

ERLC_OPTS += +debug_info
ERLC_OPTS += +'{parse_transform, lager_transform}'

NO_AUTOPATCH = cuttlefish


COVER = true

include erlang.mk

app:: rebar.config

app.config::
	./deps/cuttlefish/cuttlefish -l info -e etc/ -c etc/emq_kafka_hook.conf -i priv/emq_kafka_hook.schema -d data
