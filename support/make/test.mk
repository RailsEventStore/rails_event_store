test: ## Run unit tests
	@echo "Running unit tests"
	@DATABASE_URL=$(DATABASE_URL) bundle exec rspec --tag ~integration

test-fast: ## Run unit tests with --fail-fast --order defined --backtrace
	@echo "Running unit tests with --fail-fast"
	@DATABASE_URL=$(DATABASE_URL) bundle exec rspec --tag ~integration --fail-fast --order defined --backtrace

integration: ## Run integration tests
	@DATABASE_URL=$(DATABASE_URL) bundle exec rspec --tag integration
