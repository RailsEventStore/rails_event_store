### 0.2.0 2026-08-20

- Change: process manager classes no longer define a constructor. Instead of `Klass.new(event_store, command_bus)`, dependencies are injected via `Klass.new.with(event_store:, command_bus:)`. This allows a process manager to be subclassed from a framework class that instantiates it without arguments (e.g. `ActiveJob::Base`), enabling asynchronous handling.  
  **This is a breaking change**. Please update your process manager classes to use `with` for dependency injection.
- Add: calling `call` before `with` raises a clear error naming the missing dependencies, instead of failing deep inside `build_state` or `act`.

### 0.1.0 2026-02-11

- initial release
