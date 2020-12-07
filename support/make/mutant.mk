mutate: ## Run mutation tests
	@echo "Running mutation tests"
	@DATABASE_URL=$(DATABASE_URL) bundle exec mutant run \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		$(if $(MUTANT_JOBS), --jobs $(MUTANT_JOBS)) \
		"$(SUBJECT)"

mutate-fast: ## Run mutation tests with --fail-fast
	@echo "Running mutation tests"
	@DATABASE_URL=$(DATABASE_URL) bundle exec mutant run \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		$(if $(MUTANT_JOBS), --jobs $(MUTANT_JOBS)) \
		--fail-fast \
		"$(SUBJECT)"

mutate-changes: ## Run incremental mutation tests
	@echo "Running mutation tests"
	@DATABASE_URL=$(DATABASE_URL) bundle exec mutant run \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		$(if $(MUTANT_JOBS), --jobs $(MUTANT_JOBS)) \
		--since HEAD~1 \
		"$(SUBJECT)"
