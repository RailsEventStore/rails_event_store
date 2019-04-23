install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle check || bundle install

remove-lock:
	@echo "Removing resolved dependency versions"
	-rm Gemfile.lock

reinstall: remove-lock install ## Removing resolved dependency versions
