GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = ruby_event_store-browser
DATABASE_URL ?= sqlite3::memory:
BUNDLE       = public/ruby_event_store_browser.js public/ruby_event_store_browser.css public/ruby_event_store_browser.js.map public/ruby_event_store_browser.css.map

include ../support/make/install.mk
include ../support/make/test.mk
include ../support/make/mutant.mk
include ../support/make/gem.mk
include ../support/make/help.mk

install: install-npm

test: $(BUNDLE) test-npm

build: $(BUNDLE)

push: $(BUNDLE)

clean: clean-npm

watch-elm: clean-npm ## Start dev frontend
	@cd elm; npm run watch

dev-server: ## Start dev backend prepopulated with events
	@bundle exec rackup --port 9393 devserver/config.ru

install-npm:
	@echo "Installing npm dependencies"
	@cd elm; npm install --no-fund --no-audit

test-npm:
	@cd elm; npx elm-test

clean-npm:
	-rm $(BUNDLE)

$(BUNDLE):
	@echo "Building browser frontend"
	@cd elm; npm run build
