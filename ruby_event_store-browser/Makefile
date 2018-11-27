GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = ruby_event_store-browser
REQUIRE      = ruby_event_store/browser
IGNORE       =
SUBJECT      ?= RubyEventStore::Browser*
DATABASE_URL ?= sqlite3::memory:
JS_BUNDLE    = public/ruby_event_store_browser.js

include ../lib/install.mk
include ../lib/test.mk
include ../lib/mutant.mk
include ../lib/gem.mk
include ../lib/help.mk

install: install-yarn

test: $(JS_BUNDLE) test-yarn

build: $(JS_BUNDLE)

push: $(JS_BUNDLE)

clean: clean-yarn

install-yarn:
	@echo "Installing yarn dependencies"
	@cd elm; yarn install

test-yarn:
	@cd elm; yarn test; cd -

clean-yarn:
	-rm $(JS_BUNDLE)

$(JS_BUNDLE):
	@echo "Building browser frontend"
	@cd elm; yarn build