GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = ruby_event_store-active_record

include ../support/make/install.mk
include ../support/make/test.mk
include ../support/make/mutant.mk
include ../support/make/gem.mk
include ../support/make/help.mk

docker-test: ## Run the test suite in Docker against Postgres/MySQL (no Ruby install required)
	@docker compose -f ../support/docker/docker-compose.test.yml run --rm test

docker-mutate: ## Run mutation testing in Docker against Postgres/MySQL
	@docker compose -f ../support/docker/docker-compose.test.yml run --rm mutate

