[![Build Status](https://travis-ci.org/arkency/rails_event_store_active_record.svg?branch=master)](https://travis-ci.org/arkency/rails_event_store_active_record)
[![Gem Version](https://badge.fury.io/rb/rails_event_store_active_record.svg)](http://badge.fury.io/rb/rails_event_store_active_record)
[![Code Climate](https://codeclimate.com/github/arkency/rails_event_store_active_record/badges/gpa.svg)](https://codeclimate.com/github/arkency/rails_event_store_active_record)
[![Test Coverage](https://codeclimate.com/github/arkency/rails_event_store_active_record/badges/coverage.svg)](https://codeclimate.com/github/arkency/rails_event_store_active_record)
[![Join the chat at https://gitter.im/arkency/rails_event_store](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/arkency/rails_event_store?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# Events repository

A Active Record based implementation of events repository for [Rails Event Store](http://github.com/arkency/rails_event_store).
It is a default events repository used by RailsEventStore.

# Documentation

All documentation and sample codes are available at [http://railseventstore.arkency.com](http://railseventstore.arkency.com)

# Contributing

Check the contribution guide on [CONTRIBUTING.md](https://github.com/arkency/rails_event_store_active_record/blob/master/CONTRIBUTING.md)

We're aiming for 100% mutation coverage in this project.
Read the reasoning:

[Why I want to introduce mutation testing to the rails_event_store gem](http://blog.arkency.com/2015/04/why-i-want-to-introduce-mutation-testing-to-the-rails-event-store-gem/)

[Mutation testing and continuous integration](http://blog.arkency.com/2015/05/mutation-testing-and-continuous-integration/)

In practice, it means that we run `make mutate` as part of the CI process. As long as we don't have 100%, there's a hardcoded value we expect from the mutation coverage.

Whenever you fix a bug or add a new feature, we require that the coverage doesn't go down.

However, even if it goes up, you need to go the `Makefile` and apply the new expected coverage. We call this technique "raising the coverage bar". The goal here is to raise the bar so that the better coverage is maintained for later changes. The new value should be the Kills/Mutations number in your last `make mutate` output.

## About

<img src="http://arkency.com/images/arkency.png" alt="Arkency" width="20%" align="left" />

Rails Event Store is funded and maintained by Arkency. Check out our other [open-source projects](https://github.com/arkency).

You can also [hire us](http://arkency.com) or [read our blog](http://blog.arkency.com).
