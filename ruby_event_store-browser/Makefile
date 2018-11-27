GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = ruby_event_store-browser
REQUIRE      = ruby_event_store/browser
IGNORE       =
SUBJECT      ?= RubyEventStore::Browser*
DATABASE_URL ?= sqlite3::memory:
JS_BUNDLE    = public/ruby_event_store_browser.js

install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install
	@echo "Installing npm dependencies"
	@cd elm; yarn install

remove-lock:
	@echo "Removing resolved dependency versions"
	-rm Gemfile.lock

reinstall: remove-lock install ## Removing resolved dependency versions

test: $(JS_BUNDLE) ## Run unit tests
	@echo "Running unit and integration tests"
	@cd elm; yarn test; cd -
	@bundle exec rspec

include ../lib/mutant.mk

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
	@gem push -k dev_arkency pkg/$(GEM_NAME)-$(GEM_VERSION).gem

clean:
	@echo "Removing previously built package and bundle"
	-rm pkg/$(GEM_NAME)-$(GEM_VERSION).gem $(JS_BUNDLE)

include ../lib/help.mk


