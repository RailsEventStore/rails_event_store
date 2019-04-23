GEM_VERSION  = $(shell cat lib/dres_client/version.rb | grep VERSION | egrep -o '\d+\.\d+\.\d+')
GEM_NAME     = dres_client
REQUIRE      = $(GEM_NAME)
DATABASE_URL ?= postgres://localhost/rails_event_store_active_record?pool=5

install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install
	@gem install gemfury

test: ## Run unit tests
	@echo "Running unit tests"
	@bundle exec rspec

build:
	@echo "Building gem package"
	@gem build -V dres_client.gemspec
	@mkdir -p pkg/
	@mv dres_client-*.gem pkg/

push:
	@echo "Pushing package to Gemfury"
	@fury push pkg/$(GEM_NAME)-$(GEM_VERSION).gem

clean:
	@echo "Removing previously built package"
	-rm pkg/$(GEM_NAME)-$(GEM_VERSION).gem

release: install test build push clean

version:
	@echo "Lists versions"
	@echo $(GEM_VERSION)

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.DEFAULT_GOAL := help
