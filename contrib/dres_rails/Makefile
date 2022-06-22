GEM_VERSION  = $(shell cat lib/dres_rails/identity.rb | egrep -o '\d+\.\d+\.\d+')
GEM_NAME     = dres_rails
REQUIRE      = $(GEM_NAME)
DATABASE_URL ?= postgres://localhost/rails_event_store?pool=5

install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install

migrate:
	@echo "Running migrations"
	@cd spec/dummy && DATABASE_URL=$(DATABASE_URL) bundle exec bin/rails dres_rails:install:migrations
	@cd spec/dummy && DATABASE_URL=$(DATABASE_URL) bundle exec bin/rails db:migrate
	@cd spec/dummy && DATABASE_URL=$(DATABASE_URL) RAILS_ENV=test bundle exec bin/rails db:migrate

test: migrate ## Run unit tests
	@echo "Running unit tests"
	@env DATABASE_URL=$(DATABASE_URL) bundle exec rspec

build:
	@echo "Building gem package"
	@gem build -V dres_rails.gemspec
	@mkdir -p pkg/
	@mv dres_rails-*.gem pkg/

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
