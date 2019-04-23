GEM_VERSION  = $(shell cat lib/dres_rails/identity.rb | egrep -o '\d+\.\d+\.\d+')
GEM_NAME     = dres_rails
REQUIRE      = $(GEM_NAME)
DATABASE_URL ?= postgres://localhost/rails_event_store_active_record?pool=5

install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install
	@gem install gemfury -v 0.7.0 --conservative
	@echo "Running migrations"
	@cd spec/dummy/ && bundle exec bin/rails dres_rails:install:migrations && cd ../../
	@cd spec/dummy/ && bundle exec bin/rails db:migrate && cd ../../
	@cd spec/dummy/ && RAILS_ENV=test bundle exec bin/rails db:migrate && cd ../../

test: ## Run unit tests
	@echo "Running unit tests"
	@bundle exec rspec

build:
	@echo "Building gem package"
	@gem build -V dres_rails.gemspec
	@mkdir -p pkg/
	@mv dres_rails-*.gem pkg/

push:
	@echo "Pushing package to Gemfury"
	@fury push pkg/$(GEM_NAME)-$(GEM_VERSION).gem

clean:
	@echo "Removing previously built package"
	-rm pkg/$(GEM_NAME)-$(GEM_VERSION).gem

release: install test build push clean

version:
	@echo "Lists version"
	@echo $(GEM_VERSION)

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.DEFAULT_GOAL := help
