# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'rails_event_store-rspec'
  spec.version       = '2.0.1'
  spec.licenses      = ['MIT']
  spec.authors       = ['Arkency']
  spec.email         = ['dev@arkency.com']

  spec.summary       = %q{RSpec matchers for RailsEventStore}
  spec.homepage      = 'https://railseventstore.org'
  spec.metadata    = {
    "homepage_uri" => "https://railseventstore.org/",
    "changelog_uri" => "https://github.com/RailsEventStore/rails_event_store/releases",
    "source_code_uri" => "https://github.com/RailsEventStore/rails_event_store",
    "bug_tracker_uri" => "https://github.com/RailsEventStore/rails_event_store/issues",
  }

  spec.files         = ['lib/rails_event_store/rspec.rb']
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'rspec', '~> 3.0'
  spec.add_runtime_dependency 'ruby_event_store-rspec', '= 2.0.3'

  spec.post_install_message = <<~EOW
    The 'rails_event_store-rspec' gem has been renamed.

    Please change your Gemfile or gemspec
    to reflect its new name:

      'ruby_event_store-rspec'

  EOW
end
