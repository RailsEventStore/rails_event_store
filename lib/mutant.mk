
mutate: test ## Run mutation tests
	@echo "Running mutation tests"
	@MUTATING=true bundle exec mutant --include lib \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		--use rspec "$(SUBJECT)"

mutate-fast: ## Run mutation tests with --fail-fast
	@echo "Running mutation tests"
	@MUTATING=true bundle exec mutant --include lib \
		$(addprefix --require ,$(REQUIRE)) \
		$(addprefix --ignore-subject ,$(IGNORE)) \
		--fail-fast \
		--use rspec "$(SUBJECT)"
