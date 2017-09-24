.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

install-aggregate-root:
	@make -C aggregate_root install

test-aggregate-root:
	@make -C aggregate_root test

mutate-aggregate-root:
	@make -C aggregate_root mutate

install-ruby-event-store:
	@make -C ruby_event_store install

test-ruby-event-store:
	@make -C ruby_event_store test

mutate-ruby-event-store:
	@make -C ruby_event_store mutate

install-rails-event-store:
	@make -C rails_event_store install

test-rails-event-store:
	@make -C rails_event_store test

mutate-rails-event-store:
	@make -C rails_event_store mutate

install-rails-event-store-active-record:
	@make -C rails_event_store_active_record install

test-rails-event-store-active-record:
	@make -C rails_event_store_active_record test

mutate-rails-event-store-active-record:
	@make -C rails_event_store_active_record mutate

install-rails-event-store-rspec:
	@make -C rails_event_store-rspec install

test-rails-event-store-rspec:
	@make -C rails_event_store-rspec test

mutate-rails-event-store-rspec:
	@make -C rails_event_store-rspec mutate

install-bounded-context:
	@make -C bounded_context install

test-bounded-context:
	@make -C bounded_context test

mutate-bounded-context:
	@make -C bounded_context mutate

git-check-clean:
	@git diff --quiet --exit-code

git-check-committed:
	@git diff-index --quiet --cached HEAD

RES_VERSION = `cat RES_VERSION`

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
	@git add -A **/*.gemspec **/version.rb
	@git ci -m "Version v$(RES_VERSION)"

release-rails-event-store:
	@make -C rails_event_store release

release-ruby-event-store:
	@make -C ruby_event_store release

release-rails-event-store-active-record:
	@make -C rails_event_store_active_record release

release-aggregate-root:
	@make -C aggregate_root release

release-rails-event-store-rspec:
	@make -C rails_event_store-rspec release

release-bounded-context:
	@make -C bounded_context release

install: install-aggregate-root install-ruby-event-store install-rails-event-store install-rails-event-store-active-record install-rails-event-store-rspec install-bounded-context ## Install all deps

test: test-aggregate-root test-ruby-event-store test-rails-event-store test-rails-event-store-active-record test-rails-event-store-rspec test-bounded-context ## Run all specs

mutate: mutate-aggregate-root mutate-ruby-event-store mutate-rails-event-store mutate-rails-event-store-active-record mutate-rails-event-store-rspec mutate-bounded-context ## Run all mutation tests

release: git-check-clean git-check-committed set-version git-tag release-rails-event-store release-ruby-event-store release-rails-event-store-active-record release-aggregate-root release-rails-event-store-rspec release-bounded-context ## Make a new release and push to RubyGems
	@echo Released v$(RES_VERSION)

UPSTREAM_REV = `git rev-parse upstream/master`
ORIGIN_REV   = `git rev-parse origin/master`
CURRENT_REV  = `git rev-parse HEAD`

rebase: git-rebase-from-upstream
	@echo "Rebased with upstream/master"
	@echo "  upstream/master at $(UPSTREAM_REV)"
	@echo "  origin/master   at $(ORIGIN_REV)"
	@echo "  current branch  at $(CURRENT_REV)"
