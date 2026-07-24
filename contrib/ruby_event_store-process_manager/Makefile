GEM_VERSION  = $(shell cat lib/ruby_event_store/process_manager/version.rb | grep VERSION | egrep -o '[0-9]+\.[0-9]+\.[0-9]+')
GEM_NAME     = ruby_event_store-process_manager
CSS_OUTFILE  = lib/ruby_event_store/process_manager/public/ruby_event_store_process_manager.css

include ../../support/make/install.mk
include ../../support/make/test.mk
include ../../support/make/mutant.mk
include ../../support/make/gem.mk
include ../../support/make/help.mk

build: css

css: ## Build the browser extension stylesheet from the templates with Tailwind
	@bundle exec tailwindcss --minify --input tailwind.css --output $(CSS_OUTFILE)
