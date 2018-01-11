GEM_VERSION  = `cat ../RES_VERSION`

install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install

test: ## Run tests
	@echo "Running basic tests - beware: this won't guarantee build pass"
	@bundle exec rspec

mutate: test  ## Run mutation tests
	@echo "Running mutation tests - only 100% free mutation will be accepted"
	@bundle exec mutant --include lib --require ruby_event_store --use rspec "RubyEventStore*" \
		--ignore-subject "RubyEventStore.const_missing" \
		--ignore-subject "RubyEventStore::InMemoryRepository#append_with_synchronize" \
		--ignore-subject "RubyEventStore::InMemoryRepository#normalize_to_array" \
		--ignore-subject "RubyEventStore::Client#normalize_to_array" \
		--ignore-subject "RubyEventStore::SerializedRecord" \
		--ignore-subject "RubyEventStore::Projection#read_events_from_stream" \
		--ignore-subject "RubyEventStore::Projection#read_events_from_all_streams"


build:
	@gem build -V ruby_event_store.gemspec
	@mkdir -p pkg/
	@mv ruby_event_store-$(GEM_VERSION).gem pkg/

release: build
	@gem push pkg/ruby_event_store-$(GEM_VERSION).gem

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.DEFAULT_GOAL := help

