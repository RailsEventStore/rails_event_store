$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "web/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "web"
  s.version     = Web::VERSION
  s.authors     = ["Anton Paisov"]
  s.email       = ["paisov@gmail.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Web."
  s.description = "TODO: Description of Web."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.1.4"

  s.add_development_dependency "sqlite3"
end
