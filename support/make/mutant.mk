mutate: ## Run mutation tests
	@echo "Running mutation tests"
	@DATA_TYPE=$(DATA_TYPE) DATABASE_URL=$(DATABASE_URL) bundle exec mutant run $(SUBJECT)

mutate-fast: ## Run mutation tests with --fail-fast
	@echo "Running mutation tests"
	@DATA_TYPE=$(DATA_TYPE) DATABASE_URL=$(DATABASE_URL) bundle exec mutant run --fail-fast $(SUBJECT)

mutate-changes: ## Run incremental mutation tests
	@echo "Running mutation tests"
	@DATA_TYPE=$(DATA_TYPE) DATABASE_URL=$(DATABASE_URL) bundle exec mutant run --since HEAD~1 $(SUBJECT)
