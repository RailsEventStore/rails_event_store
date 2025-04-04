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
		-c "make build" \
		--initial
.PHONY: watch

dev: ## Run server (development)
	@$(MAKE) -j2 watch serve
.PHONY: dev

include ../support/make/help.mk
