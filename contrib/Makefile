GEMS = minitest-ruby_event_store \
       ruby_event_store-flipper \
       ruby_event_store-newrelic \
       ruby_event_store-outbox \
       ruby_event_store-profiler \
       ruby_event_store-protobuf \
       ruby_event_store-rom \
       ruby_event_store-sidekiq_scheduler \
       ruby_event_store-transformations

$(addprefix install-, $(GEMS)):
	@make -C $(subst install-,,$@) install

$(addprefix update-, $(GEMS)):
	@make -C $(subst update-,,$@) update

$(addprefix test-, $(GEMS)):
	@make -C $(subst test-,,$@) test

$(addprefix mutate-changes-, $(GEMS)):
	@make -C $(subst mutate-changes-,,$@) mutate-changes

$(addprefix mutate-, $(GEMS)):
	@make -C $(subst mutate-,,$@) mutate

install: $(addprefix install-, $(GEMS)) ## Install all dependencies

update: $(addprefix update-, $(GEMS)) ## Update all dependencies

test: $(addprefix test-, $(GEMS)) ## Run all unit tests

mutate: $(addprefix mutate-, $(GEMS)) ## Run all mutation tests

mutate-changes: $(addprefix mutate-changes-, $(GEMS)) ## Run incremental mutation tests

clean: $(addprefix clean-, $(GEMS)) ## Remove all previously built packages

include ../support/make/help.mk
