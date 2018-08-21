$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'rails_event_store/browser/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = 'rails_event_store-browser'
  spec.version     = RailsEventStore::Browser::VERSION
  spec.authors     = ['Arkency']
  spec.email       = ['dev@arkency.com']
  spec.summary     = 'Web interface for RailsEventStore'
  spec.license     = 'MIT'
  spec.homepage    = 'https://railseventstore.org'
  spec.metadata    = {
    "homepage_uri" => "https://railseventstore.org/",
    "changelog_uri" => "https://github.com/RailsEventStore/rails_event_store/releases",
    "source_code_uri" => "https://github.com/RailsEventStore/rails_event_store",
    "bug_tracker_uri" => "https://github.com/RailsEventStore/rails_event_store/issues",
  }

  spec.files = Dir['{app,config,db,lib,public}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  spec.add_dependency 'rails', '>= 4.2'
  spec.add_dependency 'rails_event_store', '= 0.31.1'
  spec.add_dependency 'ruby_event_store-browser', '= 0.31.1'

  spec.add_development_dependency 'rails', '~> 5.2'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'rspec-rails', '~> 3.6'
  spec.add_development_dependency 'mutant-rspec', '~> 0.8.15'
  spec.add_development_dependency 'capybara', '< 3.0.0'
  spec.add_development_dependency 'selenium-webdriver'
  spec.add_development_dependency 'json-schema'
end
