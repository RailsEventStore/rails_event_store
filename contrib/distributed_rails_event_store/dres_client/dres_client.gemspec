
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dres_client/version"

Gem::Specification.new do |spec|
  spec.name          = "dres_client"
  spec.version       = DresClient::VERSION
  spec.authors       = ["Robert Pankowecki"]
  spec.email         = ["dev@arkency.com"]
  spec.summary       = %q{Distributed RailsEventStore (DRES) client}
  spec.description   = %q{Distributed RailsEventStore (DRES) client}
  spec.homepage      = "http://railseventstore.org/"
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.5"

  spec.add_dependency "ruby_event_store", ">= 2.0", "< 3.0"
end
