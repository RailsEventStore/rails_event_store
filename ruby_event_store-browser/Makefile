GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = ruby_event_store-browser
JS_OUTFILE   = public/ruby_event_store_browser.js

include ../support/make/install.mk
include ../support/make/test.mk
include ../support/make/mutant.mk
include ../support/make/gem.mk
include ../support/make/help.mk

install: install-npm

test: $(JS_OUTFILE) test-elm

build: $(JS_OUTFILE)

push: $(JS_OUTFILE)

clean: clean-elm

clean-elm:
	@rm $(JS_OUTFILE) 2>/dev/null || true

watch-elm: clean-elm
	@cd elm; \
		npx chokidar-cli "src/**/*.elm" \
			-c "npx elm make src/Main.elm --output ../$(JS_OUTFILE)" \
			--initial

dev: ## Start standalone browser seeded with some events and Elm recompile on change
	@$(MAKE) -j2 serve watch-elm

serve:
	@bundle exec rackup --port 9393 devserver/config.ru

install-npm:
	@cd elm; npm install --no-fund --no-audit

test-elm:
	@cd elm; npx elm-test

public/ruby_event_store_browser.js:
	@echo "Building browser JS"
	@cd elm; npx elm make --optimize --output=../public/ruby_event_store_browser.js src/Main.elm > /dev/null
	@cd elm; npx uglify-js ../public/ruby_event_store_browser.js --compress "pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe" | npx uglify-js --mangle --output ../public/ruby_event_store_browser.js

