GEM_VERSION = $(shell cat ../RES_VERSION)
GEM_NAME    = ruby_event_store
REQUIRE     = $(GEM_NAME)
SUBJECT     ?= RubyEventStore*

install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install

test: ## Run unit tests
	@echo "Running unit tests"
	@bundle exec rspec

mutate: test  ## Run mutation tests
	@echo "Running mutation tests"
	@bundle exec mutant --include lib --require $(REQUIRE) --use rspec "$(SUBJECT)" \
		--ignore-subject "RubyEventStore.const_missing" \
		--ignore-subject "RubyEventStore::InMemoryRepository#append_with_synchronize" \
		--ignore-subject "RubyEventStore::InMemoryRepository#normalize_to_array" \
		--ignore-subject "RubyEventStore::Client#normalize_to_array" \
		--ignore-subject "RubyEventStore::SerializedRecord" \
		--ignore-subject "RubyEventStore::Projection#read_events_from_stream" \
		--ignore-subject "RubyEventStore::Projection#read_events_from_all_streams"

build:
	@echo "Building gem package"
	@gem build -V $(GEM_NAME).gemspec
	@mkdir -p pkg/
	@mv $(GEM_NAME)-$(GEM_VERSION).gem pkg/

push:
	@echo "Pushing package to RubyGems"
	@gem push pkg/$(GEM_NAME)-$(GEM_VERSION).gem

clean:
	@echo "Removing previously built package"
	-rm pkg/$(GEM_NAME)-$(GEM_VERSION).gem

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.DEFAULT_GOAL := help

