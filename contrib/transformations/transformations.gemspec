lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "transformations/version"

Gem::Specification.new do |spec|
  spec.name          = "transformations"
  spec.version       = Transformations::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ["arkency"]
  spec.email         = ["dev@arkency.com"]

  spec.summary       = %q{Community transformations for RubyEventStore mappers pipeline}

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]
  spec.add_dependency 'ruby_event_store', '>= 0.40.0'
end
