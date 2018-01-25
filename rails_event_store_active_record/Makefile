GEM_VERSION = $(shell cat ../RES_VERSION)
GEM_NAME    = rails_event_store_active_record
REQUIRE     = $(GEM_NAME)
SUBJECT     ?= RailsEventStoreActiveRecord*

install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install
	@echo "Installing v1_v2_schema_migration gem dependencies"
	@BUNDLE_GEMFILE=spec/v1_v2_schema_migration/Gemfile bundle install

test: ## Run unit tests
	@echo "Running unit tests"
	@bundle exec rspec

mutate: test  ## Run mutation tests
	@echo "Running mutation tests"
	@bundle exec mutant --include lib --require $(REQUIRE) --use rspec "$(SUBJECT)" \
		--ignore-subject "RailsEventStoreActiveRecord::IndexViolationDetector#detect"

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

