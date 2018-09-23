GEM_VERSION = $(shell cat ../RES_VERSION)
GEM_NAME    = rails_event_store
REQUIRE     = $(GEM_NAME)
IGNORE      = RailsEventStore.const_missing \
              RailsEventStore::Client\#initialize \
              RailsEventStore::AsyncProxyStrategy::AfterCommit::AsyncRecord\#rolledback! \
              RailsEventStore::AsyncProxyStrategy::AfterCommit::AsyncRecord\#before_committed!
SUBJECT     ?= RailsEventStore*

install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install

remove-lock:
	@echo "Removing resolved dependency versions"
	-rm Gemfile.lock

reinstall: remove-lock install ## Removing resolved dependency versions

test: ## Run unit tests
	@echo "Running unit tests"
	@bundle exec rspec

mutate: test ## Run mutation tests
	@echo "Running mutation tests"
	@MUTATING=true bundle exec mutant --include lib \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		--use rspec "$(SUBJECT)"

build:
	@echo "Building gem package"
	@gem build -V $(GEM_NAME).gemspec
	@mkdir -p pkg/
	@mv $(GEM_NAME)-$(GEM_VERSION).gem pkg/

push:
	@echo "Pushing package to RubyGems"
	@gem push -k dev_arkency pkg/$(GEM_NAME)-$(GEM_VERSION).gem

clean:
	@echo "Removing previously built package"
	-rm pkg/$(GEM_NAME)-$(GEM_VERSION).gem

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.DEFAULT_GOAL := help
