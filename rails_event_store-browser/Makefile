GEM_VERSION = $(shell cat ../RES_VERSION)
GEM_NAME    = rails_event_store-browser
REQUIRE     = rails_event_store/browser
SUBJECT     ?= RailsEventStore::Browser*
DUMMY_RAILS = ./spec/dummy_5_1_4/config/environment
JS_BUNDLE   = public/rails_event_store_browser.js

install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install
	@echo "Installing npm dependencies"
	@cd elm; yarn install

test: $(JS_BUNDLE) ## Run unit tests
	@echo "Running unit and integration tests"
	@cd elm; yarn test; cd -
	@bundle exec rspec

mutate: ## Run mutation tests
	@echo "Running mutation tests"
	@bundle exec mutant --include lib --require $(DUMMY_RAILS) --require $(REQUIRE) --use rspec "$(SUBJECT)"

$(JS_BUNDLE):
	@echo "Building browser frontend"
	@cd elm; yarn build

build: $(JS_BUNDLE)
	@echo "Building gem package"
	@gem build -V $(GEM_NAME).gemspec
	@mkdir -p pkg/
	@mv $(GEM_NAME)-$(GEM_VERSION).gem pkg/

push: $(JS_BUNDLE)
	@echo "Pushing package to RubyGems"
	@gem push pkg/$(GEM_NAME)-$(GEM_VERSION).gem

clean:
	@echo "Removing previously built package and bundle"
	-rm pkg/$(GEM_NAME)-$(GEM_VERSION).gem $(JS_BUNDLE)

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.DEFAULT_GOAL := help

