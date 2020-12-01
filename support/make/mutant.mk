mutate: ## Run mutation tests
	@echo "Running mutation tests"
	@DATABASE_URL=$(DATABASE_URL) bundle exec mutant run -t 10 --include lib \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		$(if $(MUTANT_JOBS), --jobs $(MUTANT_JOBS)) \
		--use rspec "$(SUBJECT)"

mutate-fast: ## Run mutation tests with --fail-fast
	@echo "Running mutation tests"
	@DATABASE_URL=$(DATABASE_URL) bundle exec mutant run -t 10 --include lib \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		$(if $(MUTANT_JOBS), --jobs $(MUTANT_JOBS)) \
		--fail-fast \
		--use rspec "$(SUBJECT)"

mutate-changes: ## Run mutation tests for all changes since origin/HEAD
	@echo "Running mutation tests"
	@DATABASE_URL=$(DATABASE_URL) bundle exec mutant run -t 10 --include lib \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		$(if $(MUTANT_JOBS), --jobs $(MUTANT_JOBS)) \
		--since origin/HEAD \
		--use rspec "$(SUBJECT)"
