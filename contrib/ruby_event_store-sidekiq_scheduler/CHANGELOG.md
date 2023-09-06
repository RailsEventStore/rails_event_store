### 0.1.2

- Add: Support Sidekiq::Job::Setter as a valid handler for SidekiqScheduler [b82d61b6a046d79e0c58473cd3aa1ca9d10a10fe]

### 0.1.1

- Add: Support for Sidekiq 7

  Bring compatibility with Sidekiq 7 by transforming the Sidekiq JSON payload keys to strings. [f1fd21554b339cb8b7c4c9855fa71e7ff9d495f8]

- Fix: YAML support under Ruby 3.1 and Psych 4.0 [#1294]
  
  Up until now regular YAML module shipped with Ruby was used as a default serializer. However, with release of Ruby 3.1 this module started to use Psych 4 instead of Psych 3. This, in turn, resulted in a breaking change when non-primitive values were serialized and deserializes, as since version 4 Psych does "safe loading" by default, which disallows deserializing objects such as BigDecimal or Time. As this breaking change also leaks into RES (old events would no longer be correctly deserialized afer upgrading to Ruby 3.1), a proxy serializer is introduced.

### 0.1.0

- initial release
