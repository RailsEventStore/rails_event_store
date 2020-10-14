---
title: GDPR Considerations
---

[General Data Protection Regulation](https://eur-lex.europa.eu/legal-content/EN/TXT/PDF/?uri=CELEX:32016R0679) and its "Article 17. Right to erasure ('right to be forgotten')" imposes some challenges on event sourced applications.

## Personally Identifiable Information in persisted events

There are several approaches to handle personal information (i.e. full name or an email address) in event sourced systems, each having its pros and cons.

### Not having PII in domain events in the first place

Store personal information outside of an event store and only reference related event data stored elsewhere. No changes in events are then needed when PII is requested to be forgotten.

When needed on the "read" side, event data and PII should be joined together. This introduces some complexity and may have performance implications.

Implementing this solution for existing events with PII can be a challenge to refactor. It also affects domain event design — applying a technical solution over the domain model.

### Removing sensitive data from events on request

Remove or overwrite personal information in event data. In this scenaro the events stay in the event store although their content is changed.

The challenging part is tracking which events need to be anonymized on PII removal request. Finding the ones related to a particular person can be time consuming and difficult. In order to avoid that, events can be [linked](/docs/v1/link) into an additional per-person stream upfront when published. When the removal request is received, one has to iterate only on events related to this particular person identified in a single stream.

This solution does not affect domain modeling.

Beware — [changing](https://railseventstore.org/docs/v1/migrating_messages/) event data has further implications. Events can no longer be assumed immutable and all the benefits of immutability [disappear](https://leanpub.com/esversioning/read#leanpub-auto-immutability). All consumers of such mutable events are affected and have to somehow be notified of any  change.

### Cryptographic erasure

Encrypt sensitive event data and discard the decryption key when the right to be forgotten is exercised. Without the key it is impossible to read the encrypted event data. The unencrypted part of the event data, however, still remains usable.

This solution does not affect domain modeling. There is also no modification of event data — immutability remains. The ability to decrypt and read useful data is governed by availability of the key.

Cryptography is performed on loading/storing of events in the event store. With the addition of event schemas this becomes transparent to consumers.

The challenging part is the considerations involved with cryptography:

* Rotating keys and [cryptoperiod](https://www.keylength.com/en/3/) are to be considered.
* When a particular encryption algorithm becomes weak over time or the key is leaked, the data encrypted with it becomes vulnerable.
* Cryptography might affect the performance a bit as well.

#### EncryptionMapper

RailsEventStore provides a specialized mapper to support attribute encryption for event data.

```ruby
RailsEventStore::Client.new(
  mapper: RubyEventStore::Mappers::EncryptionMapper.new(
    key_repository,
    serializer: YAML
  )
)
```

This mapper relies on `key_repository` to provide cryptographic keys. Event definitions must include `encryption_schema` which describes what attributes are to be encrypted and an identifier of the key used to perform that operation.


```ruby
class TicketHolderEmailProvided < RubyEventStore::Event
  SCHEMA = {
    ticket_id: Integer,
    user_id: UUID,
    email: String
  }

  def self.strict(data: nil, metadata: nil)
    ClassyHash.validate_strict(data, SCHEMA, true)
    new(data: data, metadata: metadata)
  end

  def self.encryption_schema
    {
      email: ->(data) { data.fetch(:user_id) }
    }
  end
end
```

For `TicketHolderEmailProvided` we want an `email` to be encrypted with the key identified by the value of the `user_id` attribute.

Each encrypted attribute of a persisted event has a corresponding cipher, key identifier and an IV used to encrypt it. This allows decryption at a later time despite changing the default cipher to a new one. [IV](https://security.stackexchange.com/questions/6058/is-real-salt-the-same-as-initialization-vectors/6059#6059) is chosen randomly for each encrypt operation. This means that encrypting the same data with the same key will result in different cryptograms.

When the decryption key is lost and an attribute can no longer be read, an instance of `RubyEventStore::Mappers::ForgottenData` is returned instead. This "Null Object" responds to any method and can be coerced to string via the `#to_s` method. It is also possible to configure a custom object for forgotten data:

```ruby
RailsEventStore::Client.new(
  mapper: RubyEventStore::Mappers::EncryptionMapper.new(
    key_repository,
    forgotten_data: MyCustomObject.new
  )
)
```

#### Implementing an encryption key repository

RailsEventStore comes with an in-memory implementation of a key repository. This `RubyEventStore::Mappers::InMemoryEncryptionKeyRepository` is good for testing and as a reference implementation.

You will have to implement your own key repository to meet security demands of your organization. Whether it is an ActiveRecord-backed model or an adapter for [Vault](https://www.vaultproject.io), the following interface is needed:

```ruby
class InMemoryEncryptionKeyRepository
  DEFAULT_CIPHER = 'aes-256-cbc'.freeze

  def initialize
    @keys = {}
  end

  def key_of(identifier, cipher: DEFAULT_CIPHER)
    @keys[[identifier, cipher]]
  end

  def create(identifier, cipher: DEFAULT_CIPHER)
    @keys[[identifier, cipher]] = RubyEventStore::Mappers::EncryptionKey.new(
      cipher: cipher,
      key: random_key(cipher)
    )
  end

  def forget(identifier)
    @keys = @keys.reject { |(id, _)| id.eql?(identifier) }
  end

  private
  def random_key(cipher)
    crypto = OpenSSL::Cipher.new(cipher)
    crypto.encrypt
    crypto.random_key
  end
end
```

## Collecting request metadata

The unique request ID and IP address from which the request originated are [collected and stored](/docs/v1/request_metadata) in event metadata by default.

In order to fully disable them, pass an empty lambda:

```ruby
RailsEventStore::Client.new(
  request_metadata: -> (env) { }
)
```

## CQRS

Read models projected from events have to be rebuilt or modified in case of changes to event data. This applies to cryptographic erasure as well.
