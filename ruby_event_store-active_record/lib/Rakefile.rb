require "active_record"
require "yaml"
require_relative "../../support/helpers/migrator"

def migration_code(data_type)
  Migrator.new(
    File.expand_path(
      "./ruby_event_store/active_record/generators/templates",
      __dir__
    )
  ).migration_code("create_event_store_events", data_type: data_type)
end

def migration_path
  ARGV[2] || "db/migrate"
end

def timestamp
  Time.now.strftime("%Y%m%d%H%M%S")
end

def write_to_file(migration_code, path)
  File.open(path, 'w') do |file|
    file.write <<-EOF
#{migration_code}
    EOF
  end
end

def path
  File.expand_path("../#{migration_path}/#{timestamp}_create_event_store_events.rb", __FILE__)
end

namespace :g do
  desc "Generate migration"
  task :migration do
    data_type = ARGV[1] || raise("Specify name: rake g:migration data_type")
    DATA_TYPES = %w[binary json jsonb].freeze
    raise ArgumentError, "DATA_TYPE must be: #{DATA_TYPES.join(", ")}" unless DATA_TYPES.include?(data_type)

    migration_code = migration_code(data_type)

    write_to_file(migration_code, path)

    puts "Migration #{path} created"

    exit
  end
end