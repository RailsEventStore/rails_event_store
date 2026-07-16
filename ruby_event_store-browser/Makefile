GEM_VERSION      = $(shell cat ../RES_VERSION)
GEM_NAME         = ruby_event_store-browser
STIMULUS_VERSION = 3.2.2
CSS_OUTFILE      = public/ruby_event_store_browser.css
STIMULUS_JS      = public/stimulus-$(STIMULUS_VERSION).js

include ../support/make/install.mk
include ../support/make/test.mk
include ../support/make/mutant.mk
include ../support/make/gem.mk
include ../support/make/help.mk

build: css $(STIMULUS_JS)

test mutate mutate-changes: css $(STIMULUS_JS)

css: ## Build the stylesheet from the templates with Tailwind
	@bundle exec tailwindcss --minify --input tailwind.css --output $(CSS_OUTFILE)

$(STIMULUS_JS): ## Vendor the pinned Stimulus runtime from the CDN
	@echo "Downloading @hotwired/stimulus $(STIMULUS_VERSION)"
	@curl -sL -o $(STIMULUS_JS) "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@$(STIMULUS_VERSION)/+esm"


dev: ## Start standalone browser seeded with some events
	@bundle exec rackup --port 9393 devserver/config.ru

clean: clean-assets

clean-assets:
	@rm -f $(CSS_OUTFILE) $(STIMULUS_JS)
