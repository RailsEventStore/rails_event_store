UPSTREAM_REV = `git rev-parse upstream/master`
ORIGIN_REV   = `git rev-parse origin/master`
CURRENT_REV  = `git rev-parse HEAD`
RES_VERSION  = `cat RES_VERSION`
GEMS         = aggregate_root bounded_context rails_event_store rails_event_store-rspec rails_event_store_active_record ruby_event_store

$(addprefix install-, $(GEMS)):
	@make -C $(subst install-,,$@) install

$(addprefix test-, $(GEMS)):
	@make -C $(subst test-,,$@) test

$(addprefix mutate-, $(GEMS)):
	@make -C $(subst mutate-,,$@) mutate

$(addprefix release-, $(GEMS)):
	@make -C $(subst release-,,$@) release

git-check-clean:
	@git diff --quiet --exit-code

git-check-committed:
	@git diff-index --quiet --cached HEAD

git-tag:
	@git tag -m "Version v$(RES_VERSION)" v$(RES_VERSION)
	@git push origin master --tags

git-rebase-from-upstream:
	@git remote remove upstream > /dev/null 2>&1 || true
	@git remote add upstream git@github.com:RailsEventStore/rails_event_store.git
	@git fetch upstream master
	@git rebase upstream/master
	@git push origin master

set-version:
	@find . -name version.rb -exec sed -i "" "s/\(VERSION = \)\(.*\)/\1\"$(RES_VERSION)\"/" {} \;
	@find . -name *.gemspec -exec sed -i "" "s/\('ruby_event_store', \)\(.*\)/\1'= $(RES_VERSION)'/" {} \;
	@find . -name *.gemspec -exec sed -i "" "s/\('rails_event_store_active_record', \)\(.*\)/\1'= $(RES_VERSION)'/" {} \;
	@find . -name *.gemspec -exec sed -i "" "s/\('aggregate_root', \)\(.*\)/\1'= $(RES_VERSION)'/" {} \;
	@find . -name *.gemspec -exec sed -i "" "s/\('rails_event_store-rspec', \)\(.*\)/\1'= $(RES_VERSION)'/" {} \;
	@find . -name *.gemspec -exec sed -i "" "s/\('bounded_context', \)\(.*\)/\1'= $(RES_VERSION)'/" {} \;
	@find . -name *.gemspec -exec sed -i "" "s/\('rails_event_store', \)\(.*\)/\1'= $(RES_VERSION)'/" {} \;
	@git add -A **/*.gemspec **/version.rb
	@git ci -m "Version v$(RES_VERSION)"

install: $(addprefix install-, $(GEMS)) ## Install all dependencies

test: $(addprefix test-, $(GEMS)) ## Run all specs

mutate: $(addprefix mutate-, $(GEMS)) ## Run all mutation tests

release: git-check-clean git-check-committed set-version git-tag $(addprefix release-, $(GEMS)) ## Make a new release and push to RubyGems
	@echo Released v$(RES_VERSION)

rebase: git-rebase-from-upstream
	@echo "Rebased with upstream/master"
	@echo "  upstream/master at $(UPSTREAM_REV)"
	@echo "  origin/master   at $(ORIGIN_REV)"
	@echo "  current branch  at $(CURRENT_REV)"

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.DEFAULT_GOAL := help


