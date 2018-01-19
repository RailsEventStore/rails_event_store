GEM_VERSION  = `cat ../RES_VERSION`

install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install
	@echo "Installing npm dependencies"
	@cd elm; yarn install

test-backend:
	@bundle exec rspec spec/api_spec.rb

test-frontend:
	@cd elm; yarn test; cd -

test-integration: build-frontend
	@bundle exec rspec spec/ui_spec.rb

test: test-frontend test-backend test-integration ## Run tests

mutate: test  ## Run mutation tests
	@echo "Running mutation tests - only 100% free mutation will be accepted"
	@bundle exec mutant --include lib --require rails_event_store/browser --require ./spec/dummy_5_1_4/config/environment --use rspec "RailsEventStore::Browser*"

build-frontend:
	@cd elm; yarn build; cd -

build: build-frontend
	@gem build -V rails_event_store-browser.gemspec
	@mkdir -p pkg/
	@mv rails_event_store-browser-$(GEM_VERSION).gem pkg/

release: build
	@gem push pkg/rails_event_store-browser-$(GEM_VERSION).gem

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.DEFAULT_GOAL := help

