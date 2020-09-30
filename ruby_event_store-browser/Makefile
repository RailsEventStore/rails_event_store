GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = ruby_event_store-browser
REQUIRE      = ruby_event_store/browser
IGNORE       =
SUBJECT      ?= RubyEventStore::Browser*
DATABASE_URL ?= sqlite3::memory:
BUNDLE       = public/ruby_event_store_browser.js public/ruby_event_store_browser.css public/ruby_event_store_browser.js.map public/ruby_event_store_browser.css.map

include ../support/make/install.mk
include ../support/make/test.mk
include ../support/make/mutant.mk
include ../support/make/gem.mk
include ../support/make/help.mk

install: install-yarn

test: $(BUNDLE) test-yarn

build: $(BUNDLE)

push: $(BUNDLE)

clean: clean-yarn

watch-elm: clean-yarn ## Start dev frontend
	@cd elm; yarn watch

dev-server: ## Start dev backend prepopulated with events
	@bundle exec rackup --port 9393 devserver/config.ru

install-yarn:
	@echo "Installing yarn dependencies"
	@cd elm; yarn install

test-yarn:
	@cd elm; yarn test

clean-yarn:
	-rm $(BUNDLE)

$(BUNDLE):
	@echo "Building browser frontend"
	@-$(if $(CI), ls -alR ~/.elm elm/elm-stuff,)
	@cd elm; yarn build
