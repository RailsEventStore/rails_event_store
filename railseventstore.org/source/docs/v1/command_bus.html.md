---
title: Command Bus
---

_Command Pattern - decoupling what is done from who does it._

## Usage

### Registering commands and their handlers

```ruby
require 'arkency/command_bus'

command_bus = Arkency::CommandBus.new
register    = command_bus.method(:register)

{ FooCommand => FooService.new(event_store: event_store).method(:foo),
  BarCommand => BarService.new,
}.map(&register)
```

### Invoking command bus with a command

```ruby
command_bus.(FooCommand.new)
```

Will call `FooService#foo` method with the command you just passed.

## New instance of a service for every invoked command

If you need a new instance of a service, every time it is called with a command, or you want to lazily load the responsible services, use `Proc` when registering commands.

```ruby
command_bus = Arkency::CommandBus.new
command_bus.register(FooCommand, -> (foo_cmd) { FooService.new(dependency: dep).foo(foo_cmd) })
command_bus.register(BarCommand, -> (bar_cmd) { BarService.new.call(bar_cmd) })
```

## Working with Rails development mode

In Rails `development` mode when you change a registered class, it is reloaded, and a new class with same name is constructed.

```ruby
a = User
a.object_id
# => 40737760

reload!
# Reloading...

b = User
b.object_id
# => 48425300

h = {a => 1, b => 2}
h[User]
# => 2

a == b
# => false
```

so your `Hash` with mapping from command class to service may not find the new version of reloaded class.

To workaround this problem you can use [`to_prepare`](http://api.rubyonrails.org/classes/Rails/Railtie/Configuration.html#method-i-to_prepare) callback which is executed before every code reload in development, and once in production.

```ruby
config.to_prepare do
  config.command_bus = Arkency::CommandBus.new
  register = command_bus.method(:register)

  { FooCommand => FooService.new(event_store: event_store).method(:foo),
    BarCommand => BarService.new,
  }.map(&register)
end
```

and call it with

```ruby
Rails.configuration.command_bus.call(FooCommand.new)
```

## Convenience alias

```ruby
require 'arkency/command_bus/alias'
```

From now on you can use top-level `CommandBus` instead of `Arkency::CommandBus`.
