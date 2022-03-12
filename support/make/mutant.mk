ifdef MUTANT_JOBS
	jobs=--jobs $(MUTANT_JOBS)
else
	jobs=
endif
mutate: ## Run mutation tests
	@echo "Running mutation tests"
	@DATABASE_URL=$(DATABASE_URL) bundle exec mutant run $(jobs) $(SUBJECT)

mutate-fast: ## Run mutation tests with --fail-fast
	@echo "Running mutation tests"
	@DATABASE_URL=$(DATABASE_URL) bundle exec mutant run --fail-fast $(jobs) $(SUBJECT)

mutate-changes: ## Run incremental mutation tests
	@echo "Running mutation tests"
	@DATABASE_URL=$(DATABASE_URL) bundle exec mutant run --since HEAD~1 $(jobs) $(SUBJECT)
