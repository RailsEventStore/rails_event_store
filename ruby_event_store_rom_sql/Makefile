GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = ruby_event_store_rom_sql
REQUIRE      = $(GEM_NAME)
IGNORE       = RubyEventStore::IndexViolationDetector\#detect
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
	@gem push pkg/$(GEM_NAME)-$(GEM_VERSION).gem

clean:
	@echo "Removing previously built package"
	-rm pkg/$(GEM_NAME)-$(GEM_VERSION).gem

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.DEFAULT_GOAL := help

