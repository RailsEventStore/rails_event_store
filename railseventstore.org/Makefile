NIX_TYPE := $(shell uname -s)

ifeq ($(NIX_TYPE),Linux)
  SED_OPTS = -i
endif

ifeq ($(NIX_TYPE),Darwin)
  SED_OPTS = -i ''
endif

install: ## Install dependencies
	@npm install --no-fund --no-audit
.PHONY: install

build: ## Output static files (production)
	@npm run build
.PHONY: build

serve:
	@npm run serve
.PHONY: serve

watch:
	@npx chokidar-cli "docs/**/*.md*" \
		"src/**/*.js" \
		-c "make build" \
		--initial
.PHONY: watch

dev: ## Run server (development)
	@$(MAKE) -j2 watch serve
.PHONY: dev

release: ## Release new docs version (VERSION=x.y.z)
	@cp -r docs versioned_docs/version-$(VERSION)
	@cp sidebars.json versioned_sidebars/version-$(VERSION)-sidebars.json
	@ruby bin/add_version.rb $(VERSION)
	@sed $(SED_OPTS) "s/[0-9]\.[0-9]*\.[0-9]/$(VERSION)/" docusaurus.config.js
.PHONY: release

include ../support/make/help.mk


