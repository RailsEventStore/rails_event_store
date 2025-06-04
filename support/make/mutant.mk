BASE_REF ?= master

mutate: ## Run mutation tests
	@echo "Running mutation tests"
	@bundle exec mutant run \
 		$(if $(MUTANT_JOBS), --jobs $(MUTANT_JOBS)) \
		$(SUBJECT)

mutate-fast: ## Run mutation tests with --fail-fast
	@echo "Running mutation tests"
	@bundle exec mutant run \
 		$(if $(MUTANT_JOBS), --jobs $(MUTANT_JOBS)) \
		--fail-fast \
		$(SUBJECT)

mutate-changes: ## Run incremental mutation tests
	@echo "Running mutation tests"
	@bundle exec mutant run \
 		$(if $(MUTANT_JOBS), --jobs $(MUTANT_JOBS)) \
		--since $(BASE_REF) \
		$(SUBJECT)
