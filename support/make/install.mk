install: ## Install gem dependencies for current Gemfile 
	@echo "Installing gem dependencies"
	@bundle install

install-all: ## Install gem dependencies from all Gemfiles
	@echo "Installing gem dependencies"
	@find . -name Gemfile\* -a ! -name \*.lock -exec bundle install --gemfile {} \;

update-all: ## Update gem dependencies in all Gemfiles
	@echo "Updating gem dependencies"
	@find . -name Gemfile\* -a ! -name \*.lock -exec bundle update --gemfile {} \;

local-install:
	@find . -name Gemfile\* -a ! -name \*.lock -exec bundle install --local --quiet --gemfile {} \;
