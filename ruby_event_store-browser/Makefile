GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = ruby_event_store-browser
JS_OUTFILE   = public/ruby_event_store_browser.js
CSS_OUTFILE   = public/ruby_event_store_browser.css

include ../support/make/install.mk
include ../support/make/test.mk
include ../support/make/mutant.mk
include ../support/make/gem.mk
include ../support/make/help.mk

install: install-npm

test: $(JS_OUTFILE) $(CSS_OUTFILE) test-elm

build: $(JS_OUTFILE) $(CSS_OUTFILE)

push: $(JS_OUTFILE) $(CSS_OUTFILE)

clean: clean-elm clean-css

clean-elm:
	@rm $(JS_OUTFILE) 2>/dev/null || true

clean-css:
	@rm $(CSS_OUTFILE) 2>/dev/null || true

watch-elm: clean-elm
	@cd elm; \
		npx chokidar-cli "src/**/*.elm" \
			-c "npx elm make src/Main.elm --output ../$(JS_OUTFILE)" \
			--initial

watch-css: clean-css
	@cd elm; \
		npx tailwindcss -w \
			-i src/style.css \
			-o ../$(CSS_OUTFILE)

dev: ## Start standalone browser seeded with some events and Elm/CSS recompile on change
	@$(MAKE) -j3 serve watch-elm watch-css

serve:
	@bundle exec rackup --port 9393 devserver/config.ru

build-npm: $(JS_OUTFILE) $(CSS_OUTFILE)

install-npm:
	@cd elm; npm install --no-fund --no-audit

test-elm:
	@cd elm; npx elm-test

$(CSS_OUTFILE):
	@echo "Building browser CSS"
	@cd elm; NODE_ENV=production npx tailwindcss -m -i src/style.css -o ../public/ruby_event_store_browser.css 2> /dev/null

$(JS_OUTFILE):
	@echo "Building browser JS"
	@cd elm; npx elm make --optimize --output=../public/ruby_event_store_browser.js src/Main.elm > /dev/null
	@cd elm; npx uglify-js ../public/ruby_event_store_browser.js --compress "pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe" | npx uglify-js --mangle --output ../public/ruby_event_store_browser.js

