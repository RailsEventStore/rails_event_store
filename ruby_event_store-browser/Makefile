GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = ruby_event_store-browser
DATABASE_URL ?= sqlite3::memory:
BUNDLE       = public/ruby_event_store_browser.js public/ruby_event_store_browser.css

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
	@cd elm; npx chokidar-cli "src/**/*.elm" -c "elm make src/Main.elm --output ../public/ruby_event_store_browser.js" --initial

watch-css: clean-npm
	@cd elm; npx tailwindcss -w -i src/style.css -o ../public/ruby_event_store_browser.css

dev-server: ## Start dev backend prepopulated with events
	@bundle exec rackup --port 9393 devserver/config.ru

install-npm:
	@echo "Installing npm dependencies"
	@cd elm; npm install --no-fund --no-audit

test-npm:
	@cd elm; npx elm-test

clean-npm:
	-rm $(BUNDLE)

public/ruby_event_store_browser.css:
	@echo "Building browser CSS"
	@cd elm; NODE_ENV=production npx tailwindcss -m -i src/style.css -o ../public/ruby_event_store_browser.css

public/ruby_event_store_browser.js:
	@echo "Building browser JS"
	@cd elm; elm make --optimize --output=../public/ruby_event_store_browser.js src/Main.elm
	@cd elm; npx uglify-js ../public/ruby_event_store_browser.js --compress "pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe" | npx uglify-js --mangle --output ../public/ruby_event_store_browser.js
