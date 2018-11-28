mutate: test ## Run mutation tests
	@echo "DATABASE_URL: $(DATABASE_URL)"
	@echo "Running mutation tests"
	@MUTATING=true DATABASE_URL=$(DATABASE_URL) bundle exec mutant --include lib \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		--use rspec "$(SUBJECT)"

mutate-fast: ## Run mutation tests with --fail-fast
	@echo "Running mutation tests"
	@MUTATING=true DATABASE_URL=$(DATABASE_URL) bundle exec mutant --include lib \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		--fail-fast \
		--use rspec "$(SUBJECT)"

mutate-changes: ## Run mutation tests for all changes since origin/HEAD
	@echo "Running mutation tests"
	@MUTATING=true DATABASE_URL=$(DATABASE_URL) bundle exec mutant --include lib \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		--since origin/HEAD \
		--use rspec "$(SUBJECT)"
