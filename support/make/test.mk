test: ## Run unit tests
	@echo "Running unit tests"
	@DATA_TYPE=$(DATA_TYPE) DATABASE_URL=$(DATABASE_URL) bundle exec rspec

test-fast: ## Run unit tests with --fail-fast --order defined --backtrace
	@echo "Running unit tests with --fail-fast"
	@DATA_TYPE=$(DATA_TYPE) DATABASE_URL=$(DATABASE_URL) bundle exec rspec --fail-fast --order defined --backtrace

