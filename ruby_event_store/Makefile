GEM_VERSION = $(shell cat ../RES_VERSION)
GEM_NAME    = ruby_event_store
REQUIRE     = $(GEM_NAME)
IGNORE      = RubyEventStore.const_missing \
              RubyEventStore::InMemoryRepository\#append_with_synchronize \
              RubyEventStore::InMemoryRepository\#normalize_to_array \
              RubyEventStore::Client\#normalize_to_array \
              RubyEventStore::Client::Within\#normalize_to_array \
              RubyEventStore::Client::Within\#add_thread_subscribers \
              RubyEventStore::Client::Within\#add_thread_global_subscribers \
              RubyEventStore::Client\#read_all_streams_forward \
              RubyEventStore::Client\#read_all_streams_backward \
              RubyEventStore::Client\#read_stream_events_forward \
              RubyEventStore::Client\#read_stream_events_backward \
              RubyEventStore::Client\#read_events_forward \
              RubyEventStore::Client\#read_events_backward \
              RubyEventStore::SerializedRecord \
              RubyEventStore::Projection\#read_events_from_stream \
              RubyEventStore::Projection\#read_events_from_all_streams
SUBJECT     ?= RubyEventStore*

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

mutate-fast: ## Run mutation tests with --fail-fast
	@echo "Running mutation tests"
	@MUTATING=true bundle exec mutant --include lib \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		--fail-fast \
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

