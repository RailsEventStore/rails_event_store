require 'ruby_event_store/rom/sql'

MIGRATIONS_PATH = 'db/migrate'

desc 'Setup ROM EventRespository environment'
task 'db:setup' do
  Dir.chdir(Dir.pwd)
  ROM::SQL::RakeSupport.env = ::RubyEventStore::ROM.configure(:sql).container
end

desc 'Copy RubyEventStore SQL migrations to db/migrate'
task 'db:migrations:copy' => 'db:setup' do
  Dir[File.join(File.dirname(__FILE__), '../../../../../../', MIGRATIONS_PATH, '/*.rb')].each do |input|
    name = File.basename(input, '.*').sub(/\d+_/, '')
    output = ROM::SQL::RakeSupport.create_migration(name, path: File.join(Dir.pwd, MIGRATIONS_PATH))

    File.write output, File.read(input)

    puts "<= migration file created #{output}"
  end
end
