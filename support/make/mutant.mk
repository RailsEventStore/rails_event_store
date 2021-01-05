mutate: ## Run mutation tests
	@echo "Running mutation tests"
	@DATABASE_URL=$(DATABASE_URL) bundle exec mutant run

mutate-fast: ## Run mutation tests with --fail-fast
	@echo "Running mutation tests"
	@DATABASE_URL=$(DATABASE_URL) bundle exec mutant run --fail-fast

mutate-changes: ## Run incremental mutation tests
	@echo "Running mutation tests"
	@DATABASE_URL=$(DATABASE_URL) bundle exec mutant run --since HEAD~1
