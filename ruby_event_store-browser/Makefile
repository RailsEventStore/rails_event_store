GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = ruby_event_store-browser
REQUIRE      = ruby_event_store/browser
IGNORE       =
SUBJECT      ?= RubyEventStore::Browser*
DATABASE_URL ?= sqlite3::memory:
BUNDLE       = public/ruby_event_store_browser.js public/ruby_event_store_browser.css public/ruby_event_store_browser.map

include ../lib/make/install.mk
include ../lib/make/test.mk
include ../lib/make/mutant.mk
include ../lib/make/gem.mk
include ../lib/make/help.mk

install: install-yarn

test: $(BUNDLE) test-yarn

build: $(BUNDLE)

push: $(BUNDLE)

clean: clean-yarn

watch-elm: clean-yarn
	@cd elm; yarn watch

dev-server:
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
	@cd elm; yarn build
