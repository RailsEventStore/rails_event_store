$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rails_event_store/browser/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails_event_store-browser"
  s.version     = RailsEventStore::Browser::VERSION
  s.authors     = ["Arkency"]
  s.email       = ["dev@arkency.com"]
  s.summary     = "Web interface for RailsEventStore"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 4.2"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec", "~> 3.6"
  s.add_development_dependency "mutant-rspec", "~> 0.8.14"
end
