
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bounded_context/version'

Gem::Specification.new do |spec|
  spec.name          = 'bounded_context'
  spec.version       = BoundedContext::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ['Arkency']
  spec.email         = ['dev@arkency.com']

  spec.summary       = %q{Generate opinionated component structure.}

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency 'rails', '~> 5.1'
  spec.add_development_dependency 'fakefs', '~> 0.11.2'
  spec.add_development_dependency 'mutant-rspec', '~> 0.8.14'
end
