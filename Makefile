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

install: install-aggregate-root install-ruby-event-store install-rails-event-store install-rails-event-store-active-record ## Install all deps

test: test-aggregate-root test-ruby-event-store test-rails-event-store test-rails-event-store-active-record ## Run all specs

mutate: mutate-aggregate-root mutate-ruby-event-store mutate-rails-event-store mutate-rails-event-store-active-record ## Run all mutation tests
