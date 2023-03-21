GEMS = minitest-ruby_event_store \
       ruby_event_store-flipper \
       ruby_event_store-newrelic \
       ruby_event_store-outbox \
       ruby_event_store-profiler \
       ruby_event_store-protobuf \
       ruby_event_store-rom \
       ruby_event_store-sidekiq_scheduler \
       ruby_event_store-transformations \
			 dres_rails \
			 dres_client


define substf
  $(shell echo $(3) | sed -e 's/$(1)/$(2)/')
endef


$(addprefix install-, $(GEMS)):
	@make -C $(subst install-,,$@) install

$(addprefix local-install-, $(GEMS)):
	@make -C $(subst local-install-,,$@) local-install

$(addprefix update-all-, $(GEMS)):
	@make -C $(subst update-all-,,$@) update-all

$(addprefix test-, $(GEMS)):
	@make -C $(call substf,test-,,$@) test

$(addprefix mutate-changes-, $(GEMS)):
	@make -C $(subst mutate-changes-,,$@) mutate-changes

$(addprefix mutate-, $(GEMS)):
	@make -C $(subst mutate-,,$@) mutate

install: $(addprefix install-, $(GEMS)) ## Install all dependencies

local-install: $(addprefix local-install-, $(GEMS))

update-all: $(addprefix update-all-, $(GEMS)) ## Update all dependencies

test: $(addprefix test-, $(GEMS)) ## Run all unit tests

mutate: $(addprefix mutate-, $(GEMS)) ## Run all mutation tests

mutate-changes: $(addprefix mutate-changes-, $(GEMS)) ## Run incremental mutation tests

clean: $(addprefix clean-, $(GEMS)) ## Remove all previously built packages

include ../support/make/help.mk
