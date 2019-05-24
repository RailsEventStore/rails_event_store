require 'erb'

class Migrator
  module Binding
    module_function

    def clean_binding
      binding
    end

    def from_hash(**variables)
      clean_binding.tap do |b|
        variables.each { |k, v| b.local_variable_set(k, v) }
      end
    end
  end

  def initialize(template_root)
    @template_root = template_root
  end

  def run_migration(name, template_name = nil)
    eval(migration_code(template_name || name))
    migration_class(name).new.change
  end

  def migration_code(name)
    migration_template(name).result(
      Binding.from_hash(
        migration_version: migration_version,
        data_type: 'binary'
      )
    )
  end

  private

  def migration_class(name)
    Migrator.const_get(name.camelize)
  end

  def migration_version
    Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("5.0.0") ? "" : "[4.2]"
  end

  def migration_template(name)
    ERB.new(File.read(File.join(@template_root, "#{name}_template.rb")))
  end
end