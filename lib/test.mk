test: ## Run unit tests
	@echo "Running unit tests"
	@bundle exec rspec

test-fast: ## Run unit tests with --fail-fast --order defined --backtrace
	@echo "Running unit tests with --fail-fast"
	@bundle exec rspec --fail-fast --order defined --backtrace
