GEM_VERSION  = `cat ../RES_VERSION`

install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install

test: ## Run tests
	@echo "Running basic tests - beware: this won't guarantee build pass"
	@bundle exec rspec

mutate: test  ## Run mutation tests
	@echo "Running mutation tests - only 100% free mutation will be accepted"
	@bundle exec mutant --include lib --require bounded_context --use rspec "BoundedContext*"

build:
	@gem build -V bounded_context.gemspec
	@mkdir -p pkg/
	@mv bounded_context-$(GEM_VERSION).gem pkg/

release: build
	@gem push pkg/bounded_context-$(GEM_VERSION).gem

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.DEFAULT_GOAL := help
