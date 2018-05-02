GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = ruby_event_store-rom
REQUIRE      = $(GEM_NAME)
IGNORE       = RubyEventStore::ROM::EventRepository\#handle_not_found_errors \
               RubyEventStore::ROM::EventRepository\#handle_unique_violation_errors \
               RubyEventStore::ROM::EventRepository\#has_event? \
               RubyEventStore::ROM::EventRepository\#last_stream_event \
               RubyEventStore::ROM::Repositories::Events\#find_nonexistent_pks \
               RubyEventStore::ROM::Repositories::StreamEntries\#create_changeset \
               RubyEventStore::ROM::Env\#handle_error \
               RubyEventStore::ROM::Env\#initialize \
               RubyEventStore::ROM::Env\#register_error_handler \
               RubyEventStore::ROM::Env\#register_unit_of_work_options \
               RubyEventStore::ROM::Env\#unit_of_work \
               RubyEventStore::ROM::UnitOfWork\#call \
               RubyEventStore::ROM::UnitOfWork\#commit! \
               RubyEventStore::ROM::SQL::Relations::StreamEntries\#normalize_stream_name \
               RubyEventStore::ROM::SQL::IndexViolationDetector\#detect \
               RubyEventStore::ROM::SQL::SpecHelper\#initialize \
               RubyEventStore::ROM::SQL::SpecHelper\#has_connection_pooling? \
               RubyEventStore::ROM::SQL::SpecHelper\#close_pool_connection \
               RubyEventStore::ROM::SQL::SpecHelper\#load_gateway_schema \
               RubyEventStore::ROM::SQL::SpecHelper\#establish_gateway_connection \
               RubyEventStore::ROM::SQL::SpecHelper\#drop_gateway_schema \
               RubyEventStore::ROM::SQL::SpecHelper\#close_gateway_connection \
               RubyEventStore::ROM::SQL::SpecHelper\#run_lifecycle \
               RubyEventStore::ROM::SQL::UnitOfWork\#commit! \
               RubyEventStore::ROM::Memory::SpecHelper\#initialize \
               RubyEventStore::ROM::Memory::SpecHelper\#close_pool_connection \
               RubyEventStore::ROM::Memory::SpecHelper\#load_gateway_schema \
               RubyEventStore::ROM::Memory::SpecHelper\#establish_gateway_connection \
               RubyEventStore::ROM::Memory::SpecHelper\#drop_gateway_schema \
               RubyEventStore::ROM::Memory::SpecHelper\#close_gateway_connection \
               RubyEventStore::ROM::Memory::SpecHelper\#run_lifecycle \
               RubyEventStore::ROM::Memory::UnitOfWork\#commit!
SUBJECT      ?= RubyEventStore::ROM*
DATABASE_URL ?= sqlite::memory:

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

test-fast: ## Run unit tests with --fail-fast
	@echo "Running unit tests with --fail-fast"
	@bundle exec rspec --fail-fast --order defined --backtrace

mutate: test ## Run mutation tests
	@echo "Running mutation tests"
	@DATABASE_URL=$(DATABASE_URL) bundle exec mutant --include lib \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		--use rspec "$(SUBJECT)"

mutate-fast: ## Run mutation tests with --fail-fast
	@echo "Running mutation tests with --fail-fast"
	@DATABASE_URL=$(DATABASE_URL) bundle exec mutant --include lib \
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

