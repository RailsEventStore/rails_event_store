install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@find . -name Gemfile\* -a ! -name \*.lock -exec bundle install --gemfile {} \;

update: ## Update gem dependencies
	@echo "Updating gem dependencies"
	@find . -name Gemfile\* -a ! -name \*.lock -exec bundle update --gemfile {} \;

local-install:
	@find . -name Gemfile\* -a ! -name \*.lock -exec bundle install --local --quiet --gemfile {} \;
