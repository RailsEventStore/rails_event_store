$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'ruby_event_store/browser/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = 'ruby_event_store-browser'
  spec.version     = RubyEventStore::Browser::VERSION
  spec.authors     = ['Arkency']
  spec.email       = ['dev@arkency.com']
  spec.summary     = 'Web interface for RubyEventStore'
  spec.license     = 'MIT'
  spec.homepage    = 'https://railseventstore.org'
  spec.metadata    = {
    "homepage_uri" => "https://railseventstore.org/",
    "changelog_uri" => "https://github.com/RubyEventStore/ruby_event_store/releases",
    "source_code_uri" => "https://github.com/RubyEventStore/ruby_event_store",
    "bug_tracker_uri" => "https://github.com/RubyEventStore/ruby_event_store/issues",
  }

  spec.files = Dir['{app,config,db,lib,public}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  spec.add_dependency 'ruby_event_store', '= 0.31.1'

  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'sinatra'
  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency 'mutant-rspec', '~> 0.8.15'
  spec.add_development_dependency 'capybara', '< 3.0.0'
  spec.add_development_dependency 'selenium-webdriver'
  spec.add_development_dependency 'json-schema'
end
