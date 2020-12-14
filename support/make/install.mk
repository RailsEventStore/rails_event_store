install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@find . -name Gemfile\* -a ! -name \*.lock -exec bundle install --gemfile {} \;
