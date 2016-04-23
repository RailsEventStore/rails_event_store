# Installation

* Add following line to your application's Gemfile:

```ruby
gem 'rails_event_store'
```

* Use provided task to generate a table to store events in you DB.

```ruby
rails generate rails_event_store_active_record:migration
rake db:migrate
```
