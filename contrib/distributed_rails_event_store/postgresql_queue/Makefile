GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = postgresql_queue
REQUIRE      = $(GEM_NAME)
IGNORE       = PostgresqlQueueNothingYet
SUBJECT      ?= PostgresqlQueue*
DATABASE_URL ?= postgres://localhost/rails_event_store_active_record?pool=5

install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install

test: ## Run unit tests
	@echo "Running unit tests"
	@bundle exec rspec

mutate: test ## Run mutation tests
	@echo "Running mutation tests"
	@DATABASE_URL=$(DATABASE_URL) bundle exec mutant --include lib \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		--use rspec "$(SUBJECT)" \
		--jobs 1

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.DEFAULT_GOAL := help