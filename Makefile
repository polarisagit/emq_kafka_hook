PROJECT = emq_kafka_hook
PROJECT_DESCRIPTION = EMQ Kafka Hook
PROJECT_VERSION = 2.3.11

BUILD_DEPS = emqttd cuttlefish brod
dep_emqttd = git https://github.com/emqtt/emqttd v2.3.11
dep_cuttlefish = git https://github.com/emqtt/cuttlefish v2.0.11
dep_brod = git https://github.com/klarna/brod.git 3.7.3

ERLC_OPTS += +debug_info
ERLC_OPTS += +'{parse_transform, lager_transform}'

NO_AUTOPATCH = cuttlefish

COVER = true

include erlang.mk

app:: rebar.config

app.config::
	./deps/cuttlefish/cuttlefish -l info -e etc/ -c etc/emq_kafka_hook.conf -i priv/emq_kafka_hook.schema -d data
