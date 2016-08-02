install-bundler: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install

install: install-bundler ## Prepare current development environment

test: ## Run tests
	@echo "Running basic tests - beware: this won't guarantee build pass"
	@bundle exec rspec

mutate: test  ## Run mutation tests
	@echo "Running mutation tests - only 100% free mutation will be accepted"
	@bundle exec mutant --include lib --require aggregate_root --use rspec "AggregateRoot*" --expected-coverage 170/206

.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
