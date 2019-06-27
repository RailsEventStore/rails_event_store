# frozen_string_literal: true

require 'ruby_event_store/rom/sql'

MIGRATIONS_PATH = 'db/migrate'.freeze

desc 'Setup ROM EventRespository environment'
task 'db:setup' do
  Dir.chdir(Dir.pwd)
  ROM::SQL::RakeSupport.env = ::RubyEventStore::ROM.configure(:sql).rom_container
end

desc 'Copy RubyEventStore SQL migrations to db/migrate'
task 'db:migrations:copy' => 'db:setup' do
  # Optional data type for `data` and `metadata`
  data_type = ENV['DATA_TYPE']

  Dir[File.join(File.dirname(__FILE__), '../../../../../../', MIGRATIONS_PATH, '/*.rb')].each do |input|
    contents = File.read(input)
    name     = File.basename(input, '.*').sub(/\d+_/, '')

    re_data_type = /(ENV.+?DATA_TYPE.+?\|\|=\s*)['"](jsonb?|text)['"]/

    if data_type && contents =~ re_data_type
      # Search/replace this string: ENV['DATA_TYPE'] ||= 'text'
      contents = contents.sub(re_data_type, format('\1"%<data_type>s"', data_type: data_type))
      name    += "_with_#{data_type}"
    end

    output = ROM::SQL::RakeSupport.create_migration(name, path: File.join(Dir.pwd, MIGRATIONS_PATH))

    File.write output, contents

    puts "<= migration file created #{output}"
  end
end
