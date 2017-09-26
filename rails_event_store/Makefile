GEM_VERSION  = `cat ../RES_VERSION`

install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install

test: ## Run tests
	@echo "Running basic tests - beware: this won't guarantee build pass"
	@bundle exec rspec

mutate: test  ## Run mutation tests
	@echo "Running mutation tests - only 100% free mutation will be accepted"
	@bundle exec mutant --include lib --require rails_event_store --use rspec "RailsEventStore*" \
		--ignore-subject "RailsEventStore.const_missing"

build:
	@gem build -V rails_event_store.gemspec
	@mkdir -p pkg/
	@mv rails_event_store-$(GEM_VERSION).gem pkg/

release: build
	@gem push pkg/rails_event_store-$(GEM_VERSION).gem

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.DEFAULT_GOAL := help
