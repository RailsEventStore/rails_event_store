[![Build Status](https://travis-ci.org/arkency/rails_event_store_active_record.svg?branch=master)](https://travis-ci.org/arkency/rails_event_store_active_record)
[![Gem Version](https://badge.fury.io/rb/rails_event_store_active_record.svg)](http://badge.fury.io/rb/rails_event_store_active_record)
[![Code Climate](https://codeclimate.com/github/arkency/rails_event_store_active_record/badges/gpa.svg)](https://codeclimate.com/github/arkency/rails_event_store_active_record)
[![Test Coverage](https://codeclimate.com/github/arkency/rails_event_store_active_record/badges/coverage.svg)](https://codeclimate.com/github/arkency/rails_event_store_active_record)
[![Join the chat at https://gitter.im/arkency/rails_event_store](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/arkency/rails_event_store?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# Events repository

A Active Record based implementation of events repository for [Rails Event Store](http://github.com/arkency/rails_event_store).
It is a default events repository used by RailsEventStore.

## Installation

* Add following line to your application's Gemfile:

```ruby
gem 'rails_event_store_active_record'
```

* Use provided task to generate a table to store events in you DB.

```ruby
rails generate rails_event_store_active_record:migration
rake db:migrate
```

## About

<img src="http://arkency.com/images/arkency.png" alt="Arkency" width="20%" align="left" />

Rails Event Store is funded and maintained by Arkency. Check out our other [open-source projects](https://github.com/arkency).

You can also [hire us](http://arkency.com) or [read our blog](http://blog.arkency.com).
