GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = rails_event_store-browser
REQUIRE      = rails_event_store/browser ./spec/dummy_5_2_0/config/environment
IGNORE       =
SUBJECT      ?= RailsEventStore::Browser*
DATABASE_URL ?= sqlite3::memory:
JS_BUNDLE    = public/rails_event_store_browser.js

install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install
	@echo "Installing npm dependencies"
	@cd ../ruby_event_store-browser; cd elm; yarn install

remove-lock:
	@echo "Removing resolved dependency versions"
	-rm Gemfile.lock

reinstall: remove-lock install ## Removing resolved dependency versions

test: $(JS_BUNDLE) ## Run unit tests
	@echo "Running unit and integration tests"
	@bundle exec rspec

mutate: test ## Run mutation tests
	@echo "Running mutation tests"
	@DATABASE_URL=$(DATABASE_URL) bundle exec mutant --include lib \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		--use rspec "$(SUBJECT)"

$(JS_BUNDLE):
	@echo "Copying browser frontend"
	@cd ../ruby_event_store-browser; make public/ruby_event_store_browser.js
	@cp ../ruby_event_store-browser/public/ruby_event_store_browser.js $(JS_BUNDLE)

build: $(JS_BUNDLE)
	@echo "Building gem package"
	@gem build -V $(GEM_NAME).gemspec
	@mkdir -p pkg/
	@mv $(GEM_NAME)-$(GEM_VERSION).gem pkg/

push: $(JS_BUNDLE)
	@echo "Pushing package to RubyGems"
	@gem push -k dev_arkency pkg/$(GEM_NAME)-$(GEM_VERSION).gem

clean:
	@echo "Removing previously built package and bundle"
	-rm pkg/$(GEM_NAME)-$(GEM_VERSION).gem $(JS_BUNDLE)

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.DEFAULT_GOAL := help

