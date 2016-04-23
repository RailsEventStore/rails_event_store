Rails Event Store is a library for publishing and storing events, which can be further used to build your application state from them.

This can be a solid foundation for a design approach called [_event sourcing_](https://www.youtube.com/watch?v=JHGkaShoyNs). It has [many benefits](https://blog.arkency.com/2015/03/why-use-event-sourcing/) and is an interesting if you happen to struggle with keeping maintainability of your application at a reasonable level.

The "core" of the solution is [RubyEventStore](https://github.com/arkency/ruby_event_store) - separate gem where all concepts are implemented. Ruby Event Store is unopinionated on _how_ events are stored. [Rails Event Store](https://github.com/arkency/rails_event_store) and [Rails Event Store Active Record](https://github.com/arkency/rails_event_store_active_record) libraries provide persistence layer suitable for Ruby on Rails.

This documentation serves as a practical guide, as well as a place to describe all basic concepts you need to grasp to benefit from this design choice.
