mutate: ## Run mutation tests
	@echo "Running mutation tests"
	@MUTATING=true DATABASE_URL=$(DATABASE_URL) bundle exec mutant run --include lib \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		$(if $(MUTANT_JOBS), --jobs $(MUTANT_JOBS)) \
		--use rspec "$(SUBJECT)"

mutate-fast: ## Run mutation tests with --fail-fast
	@echo "Running mutation tests"
	@MUTATING=true DATABASE_URL=$(DATABASE_URL) bundle exec mutant run --include lib \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		$(if $(MUTANT_JOBS), --jobs $(MUTANT_JOBS)) \
		--fail-fast \
		--use rspec "$(SUBJECT)"

mutate-changes: ## Run mutation tests for all changes since origin/HEAD
	@echo "Running mutation tests"
	@MUTATING=true DATABASE_URL=$(DATABASE_URL) bundle exec mutant run --include lib \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		$(if $(MUTANT_JOBS), --jobs $(MUTANT_JOBS)) \
		--since origin/HEAD \
		--use rspec "$(SUBJECT)"
