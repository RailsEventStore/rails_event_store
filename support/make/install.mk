CURRENT_DIR = $(dir $(abspath $(firstword $(MAKEFILE_LIST))))

install: ## Install gem dependencies for current Gemfile
	@echo "Installing gem dependencies: $(CURRENT_DIR)"
	@bundle install

install-all: ## Install gem dependencies from all Gemfiles
	@echo "Installing gem dependencies: $(CURRENT_DIR)"
	@find . -name Gemfile\* -a ! -name \*.lock -exec bundle install --gemfile {} \;

update-all: ## Update gem dependencies in all Gemfiles
	@echo "Updating gem dependencies: $(CURRENT_DIR)"
	@find . -name Gemfile\* -a ! -name \*.lock -exec bundle update --gemfile {} \;
