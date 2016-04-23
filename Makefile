build: ## Build the docs
	@echo "Building docs"
	@gitbook build

publish: build ## Build the docs & publish changes
	@echo "Moving stuff around"
	@cp -rf _book/** .
	@echo "Publish changes"
	@git add docs/* gitbook/** index.html search_index.json
	@git commit -m "Automatically regenerated docs"
	@git push

.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

