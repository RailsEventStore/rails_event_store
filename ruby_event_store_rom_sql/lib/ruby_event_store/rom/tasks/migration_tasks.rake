
desc 'Setup ROM EventRespository environment'
task 'db:setup' do
  ROM::SQL::RakeSupport.env = ::RubyEventStore::ROM.configure(ENV['DATABASE_URL'])
end

desc "Copy RubyEventStore SQL migrations to db/migrate"
task 'db:copy_migrations' => 'db:setup' do
  Dir[File.join(File.dirname(__FILE__), '../../../../db/migrate/*.rb')].each do |input|
    name = File.basename(input, '.*').sub(/\d+_/, '')
    output = ROM::SQL::RakeSupport.create_migration(name)

    File.write output, File.read(input)

    puts "<= migration file created #{output}"
  end
end
