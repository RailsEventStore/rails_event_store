require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "activerecord"
  gem "pg"
end

require "active_record"

ActiveRecord::Base.establish_connection(ENV.fetch("DATABASE_URL"))
ActiveRecord::Schema.define do
  create_table :transactions, force: true do |t|
    t.string :label
    t.integer :amount
  end

  create_table :events, force: true do |t|
    t.string :name
    t.string :event_id
  end

  add_index :events, :event_id, unique: true
end

Event = Class.new(ActiveRecord::Base)
Transaction = Class.new(ActiveRecord::Base)

ActiveRecord::Base.logger =
  Logger
    .new(STDOUT)
    .tap do |l|
      l.formatter = proc { |severity, datetime, progname, msg| "#{msg}\n" }
    end

raise unless Transaction.count == 0
raise unless Event.count == 0

puts "first"
begin
  ActiveRecord::Base.transaction do
    Transaction.create(label: "kaka", amount: 100)

    event_id = SecureRandom.uuid
    Event.create(name: "deposited", event_id: event_id)
    raise ActiveRecord::Rollback
    # Event.create(name: "deposited", event_id: event_id)
  end
rescue ActiveRecord::RecordNotUnique, ActiveRecord::Rollback
end
raise unless Transaction.count == 0
raise unless Event.count == 0

puts "second"
begin
  ActiveRecord::Base.transaction do
    Transaction.create(label: "kaka", amount: 100)

    ActiveRecord::Base.transaction do
      event_id = SecureRandom.uuid
      Event.create(name: "deposited", event_id: event_id)
      raise ActiveRecord::Rollback
      # Event.create(name: "deposited", event_id: event_id)
    end
  end
rescue ActiveRecord::RecordNotUnique, ActiveRecord::Rollback
end
raise unless Transaction.count == 1
raise unless Event.count == 1

puts "third"
begin
  ActiveRecord::Base.transaction do
    Transaction.create(label: "kaka", amount: 100)

    ActiveRecord::Base.transaction(requires_new: true) do
      event_id = SecureRandom.uuid
      Event.create(name: "deposited", event_id: event_id)
      raise ActiveRecord::Rollback
      # Event.create(name: "deposited", event_id: event_id)
    end
  end
rescue ActiveRecord::RecordNotUnique, ActiveRecord::Rollback
end
raise unless Transaction.count == 2
raise unless Event.count == 1
