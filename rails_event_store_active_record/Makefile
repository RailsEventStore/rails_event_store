GEM_VERSION  = `cat ../RES_VERSION`

install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install
	@echo "Installing v1_v2_schema_migration gem dependencies"
	@BUNDLE_GEMFILE=spec/v1_v2_schema_migration/Gemfile bundle install

test: ## Run tests
	@echo "Running basic tests - beware: this won't guarantee build pass"
	@bundle exec rspec

mutate: DATABASE_URL ?= sqlite3::memory:
mutate: test  ## Run mutation tests
	@echo "Running mutation tests - only 100% free mutation will be accepted"
	@env DATABASE_URL=$(DATABASE_URL) bundle exec mutant --include lib --require ruby_event_store --use rspec "RailsEventStoreActiveRecord*" \
	  --ignore-subject "RailsEventStoreActiveRecord::EventRepository#normalize_to_array" \
	  --ignore-subject "RailsEventStoreActiveRecord::LegacyEventRepository#normalize_to_array" \
	  --ignore-subject "RailsEventStoreActiveRecord::EventRepository#detect_pkey_index_violated"

build:
	@gem build -V rails_event_store_active_record.gemspec
	@mkdir -p pkg/
	@mv rails_event_store_active_record-$(GEM_VERSION).gem pkg/

release: build
	@gem push pkg/rails_event_store_active_record-$(GEM_VERSION).gem

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.DEFAULT_GOAL := help
