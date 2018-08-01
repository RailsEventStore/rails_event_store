GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = dres_rails
REQUIRE      = $(GEM_NAME)
IGNORE       = PostgresqlQueueNothingYet
SUBJECT      ?= PostgresqlQueue*
DATABASE_URL ?= postgres://localhost/rails_event_store_active_record?pool=5

install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install
	@gem install gemfury

test: ## Run unit tests
	@echo "Running unit tests"
	@bundle exec rspec

mutate: ## Run mutation tests
	@echo "Running mutation tests"
	@DATABASE_URL=$(DATABASE_URL) bundle exec mutant --include lib \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		--jobs 1 \
		--use rspec "$(SUBJECT)"

mutate-fast: ## Run mutation tests
	@echo "Running mutation tests"
	@DATABASE_URL=$(DATABASE_URL) bundle exec mutant --include lib \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		--jobs 1 \
		--fail-fast \
		--use rspec "$(SUBJECT)"

build:
	@echo "Building gem package"
	@gem build -V dres_rails.gemspec
	@mkdir -p pkg/
	@mv dres_rails-*.gem pkg/

push:
	@echo "Pushing package to Gemfury"
	@fury push pkg/dres_rails-0.3.0.gem

clean:
	@echo "Removing previously built package"
	-rm pkg/$(GEM_NAME)-$(GEM_VERSION).gem

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.DEFAULT_GOAL := help
