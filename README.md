# RESCon - the first Rails Event Store conference!

It will be an **exclusive (limited seats)** occasion to meet Rails Event Store core team, talk with developers who are using DDD & Event Sourcing in their projects, share your experience & learn from others experience.
We have the **agenda ready** (see below) and **registration is now open!** You could register here [http://rescon.arkency.com](http://rescon.arkency.com)
This will be 3 days, each with separate Rails Event Store event and will be held from 4th to 6th of October in Wrocław, Poland (venue will be revealed soon).

### The agenda of those 3 days:

```
Thursday (4.10) / Workshop
DDD with Rails & Rails Event Store by Arkency (20 participants)

Friday (5.10) / Conference
10:00—11:30 The vision behind Rails, DDD and the RailsEventStore ecosystem - Andrzej Krzywda
12:00—13:00 Our current Rails Event Store extensions - Andrzej Śliwa
13:00—15:00 Lunch break
15:00—16:00 Introducing DDD/ES with RES in legacy systems - Mirosław Pragłowski & Paweł Pacana
16:30—18:30 Event sourcing with Rails Event Store
19:00— ..   Dinner and start of the unconference

Saturday (6.10) / Hackathon
10:00—22:00 Hackathon, improving RES, confronting ideas (free attendance, registration required)
```

And one more thing!
There will be a possibility to have private mentoring/code review sessions during hackathon (please contact us for details).

See more details at [http://rescon.arkency.com](http://rescon.arkency.com)

# Rails Event Store

[Rails Event Store (RES)](https://railseventstore.org/) is a library for publishing, consuming, storing and retrieving events. It's your best companion for going with an event-driven architecture for your Rails application.

You can use it:

<ul>
<li>as your <a href="https://railseventstore.org/docs/pubsub/">Publish-Subscribe bus</a></li>
<li>to decouple core business logic from external concerns in Hexagonal style architectures</li>
<li>as <a href="https://blog.arkency.com/2016/05/domain-events-over-active-record-callbacks/">an alternative to ActiveRecord callbacks and Observers</a></li>
<li>as a communication layer between loosely coupled components</li>
<li>to react to published events synchronously or asynchronously</li>
<li>to extract side-effects (notifications, metrics etc) from your controllers and services into event handlers</li>
<li>to build an audit-log</li>
<li>to create read-models</li>
<li>to implement event-sourcing</li>
</ul>

## Documentation

Documentation, tutorials and code samples are available at [https://railseventstore.org](https://railseventstore.org).

## Code status

[![Build Status](https://travis-ci.org/RailsEventStore/rails_event_store.svg?branch=master)](https://travis-ci.org/RailsEventStore/rails_event_store)
[![CircleCI](https://circleci.com/gh/RailsEventStore/rails_event_store.svg?style=svg)](https://circleci.com/gh/RailsEventStore/rails_event_store)
[![Gem Version](https://badge.fury.io/rb/rails_event_store.svg)](https://badge.fury.io/rb/rails_event_store)

We're aiming for 100% mutation coverage in this project. This is why:

* [Why I want to introduce mutation testing to the rails_event_store gem](https://blog.arkency.com/2015/04/why-i-want-to-introduce-mutation-testing-to-the-rails-event-store-gem/)
* [Mutation testing and continuous integration](https://blog.arkency.com/2015/05/mutation-testing-and-continuous-integration/)

Whenever you fix a bug or add a new feature, we require that the coverage doesn't go down.

## Contributing

This single repository hosts several gems and website with documentation. Check the contribution [guide](https://railseventstore.org/community/).

## About

<img src="https://arkency.com/images/arkency.png" alt="Arkency" width="60px" align="left" />

This repository is funded and maintained by [Arkency](https://arkency.com). Check out our other [open-source projects](https://github.com/arkency) and what else we have at [RES](https://github.com/RailsEventStore).

Consider [hiring us](https://arkency.com/hire-us) and make sure to check out [our blog](https://blog.arkency.com).

### Learn more about DDD & Event Sourcing

Check our [Rails + Domain Driven Design Workshop](https://blog.arkency.com/ddd-training/).
Why You should attend? Robert has explained this in a [blogpost](https://blog.arkency.com/2016/12/why-would-you-even-want-to-listen-about-ddd/).

### Read about Domain Driven Rails

You may also consider buying the [Domain-Driven Rails book](https://blog.arkency.com/domain-driven-rails/).
