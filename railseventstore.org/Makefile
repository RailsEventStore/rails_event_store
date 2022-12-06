install: ## Install dependencies
	@bundle install
	@npm install --no-fund --no-audit

build: ## Output static files (production)
	@bundle exec middleman build


dev: ## Run server (development)
	@bundle exec middleman server

include ../support/make/help.mk

.PHONY: install build dev
