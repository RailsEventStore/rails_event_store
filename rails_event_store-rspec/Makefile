GEM_VERSION = $(shell cat ../RES_VERSION)
GEM_NAME    = rails_event_store-rspec
REQUIRE     = rails_event_store/rspec
SUBJECT     ?= RailsEventStore::RSpec*

install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install

test: ## Run unit tests
	@echo "Running unit tests"
	@bundle exec rspec

mutate: test  ## Run mutation tests
	@echo "Running mutation tests"
	@bundle exec mutant --include lib --require $(REQUIRE) --use rspec "$(SUBJECT)" \
		--ignore-subject "RailsEventStore::RSpec::Matchers#differ"

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
