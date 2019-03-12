---
title: GDPR considerations
---

[General Data Protection Regulation](https://eur-lex.europa.eu/legal-content/EN/TXT/PDF/?uri=CELEX:32016R0679) and its "Article 17. Right to erasure" imposes some challenges on event sourced applications.

## Personally Identifiable Information in persisted events

There are several approaches to handle personal information (i.e. full name or an email address) in an event sourced systems, each having its pros and cons.

### Not having PII in domain events in first place

Store personal information outside of an event store and only reference it from an event data. No changes in events when PII is requested to forgotten.

When needed for the read, an event data and PII need to be joined together. This introduces some complexity and may have performance implications.

Implementing this solution for existing events with PII can be a challenging refactoring. It also affects domain event design — technical solution over domain model.


### Removing sensitive data from events on request

Remove or overwrite personal information from events data. The events stay in the event store although their content is changed.

The challenging part is tracking which events need to anonymized on PII removal request. Finding the ones related to particular person can be time consuming and difficult. In order to avoid that, events can be [linked](/docs/link) into an additional per-person stream upfront when published. When the removal request is received, one has to iterate only on events related to this particular person organized in a single stream.

This solution does not affect domain modeling.

Beware — [changing](https://railseventstore.org/docs/migrating_messages/) event data has further implications. Events can no longer be assumed immutable and all the benefits of it [disappear](https://leanpub.com/esversioning/read#leanpub-auto-immutability). Any consumers of such mutable events are affected and have to be somehow notified of change.

### Cryptographic erasure

Encrypt sensitive event data and forget the key when the right to be forgotten is exercised. Without the key it is impossible to read encrypted event data. The unencrypted part of data remains usable.

This solution does not affect domain modeling. There is also no changing of events — immutability remains. The ability to decrypt and read useful data is governed by the access to the key.

Cryptography is performed on loading/storing of events in the event store. With addition of event schemas this becomes transparent to consumers.

The challenging part is cryptography. Rotating keys and [cryptoperiod](https://www.keylength.com/en/3/) are to be considered. When a particular encryption algorithm becomes weak over time or the key is leaked, the data encrypted with it becomes vulnerable. Cryptography might affect the performance a bit as well.

#### EncryptionMapper

RailsEventStore provides a specialized mapper to support attribute encryption for events data.

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

For `TicketHolderEmailProvided` we want an `email` to be encrypted with key identified by the value of `user_id` attribute.

Each encrypted attribute of a persisted event has a corresponding description of a cipher, key identifier and an IV used to encrypt it. This allows decrypting it at a later time despite changing default cipher to a new one. [IV](https://security.stackexchange.com/questions/6058/is-real-salt-the-same-as-initialization-vectors/6059#6059) is chosen randomly for each encrypt operation. Encrypting same data with the same key will result in different cryptograms.

When decryption key is lost and an attribute can no longer be read, an instance of `RubyEventStore::Mappers::ForgottenData` is returned instead. This Null Object responds to any method and is able to coerce to string via `#to_s` method. It is possible to change this to a custom one:

```ruby
RailsEventStore::Client.new(
  mapper: RubyEventStore::Mappers::EncryptionMapper.new(
    key_repository,
    forgotten_data: MyCustomObject.new
  )
)
```

#### Implementing EncryptionKeyRepository

RailsEventStore comes with an in-memory implementation of key repository. This `RubyEventStore::Mappers::InMemoryEncryptionKeyRepository` is good for testing and as a reference implementation.

You will have to implement your own key repository to meet security demands of your organization. Whether it is an ActiveRecord backed model or an adapter for [Vault](https://www.vaultproject.io), a following interface is needed:

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

Unique request id and an IP address from which request originated are [collected and stored](/docs/request_metadata) in event metadata by default.

In order to fully disable them, pass an empty lambda:

```ruby
RailsEventStore::Client.new(
  request_metadata: -> (env) { }
)
```

## CQRS

Read models projected from events have to be rebuilt or modified in case of changes of event data. This applies to cryptographic erasure as well.
