GEM_VERSION      = $(shell cat ../RES_VERSION)
GEM_NAME         = ruby_event_store-browser
TAILWIND_VERSION = 3.4.9
STIMULUS_VERSION = 3.2.2

include ../support/make/install.mk
include ../support/make/test.mk
include ../support/make/mutant.mk
include ../support/make/gem.mk
include ../support/make/help.mk

build: css public/stimulus.js

test mutate mutate-changes: css public/stimulus.js

css: tailwindcss ## Build the stylesheet from the templates with Tailwind
	@./tailwindcss --minify --input tailwind.css --output public/ruby_event_store_browser.css

public/stimulus.js: ## Vendor the pinned Stimulus runtime from the CDN
	@echo "Downloading @hotwired/stimulus $(STIMULUS_VERSION)"
	@curl -sL -o public/stimulus.js "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@$(STIMULUS_VERSION)/+esm"

tailwindcss:
	@platform=`uname -s | tr '[:upper:]' '[:lower:]'`; \
	arch=`uname -m`; \
	case "$$platform-$$arch" in \
	  darwin-arm64)   target=macos-arm64 ;; \
	  darwin-x86_64)  target=macos-x64 ;; \
	  linux-x86_64)   target=linux-x64 ;; \
	  linux-aarch64)  target=linux-arm64 ;; \
	  *) echo "unsupported platform: $$platform-$$arch"; exit 1 ;; \
	esac; \
	echo "Downloading tailwindcss $(TAILWIND_VERSION) ($$target)"; \
	curl -sL -o tailwindcss "https://github.com/tailwindlabs/tailwindcss/releases/download/v$(TAILWIND_VERSION)/tailwindcss-$$target"; \
	chmod +x tailwindcss
