
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

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ruby_event_store", ["~> 0.28"]

  spec.add_development_dependency "pry"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.3.0"
end
