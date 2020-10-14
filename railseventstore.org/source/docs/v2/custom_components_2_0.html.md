# Migrating custom components from v1.x to v2.x

## Repository

- take serializer as an argument in `initialize`

  ```ruby
  def initialize(serializer)
    @serializer = serializer
  end
  ```

- serialize records before appending to stream with `RubyEventStore::Record#serialize`

  ```ruby
   def append_to_stream(records, stream, expected_version)
     serialized_records = records.map{ |record| record.serialize(@serializer) }
     # ...
   end
  ```
- deserialize serialized records before returning them from read operations with `RubyEventStore::SerializedRecord#deserialize`

   ```ruby
   def last_stream_event(stream)
     # ...
     serialized_record = ...
     serialized_record.deserialize(serializer) if serialized_record
   end
   
   def read(spec)
     serialized_records = ...
     if spec.batched?
       batch_reader = ->(offset, limit) do
         serialized_records
           .drop(offset)
           .take(limit)
           .map{|serialized_record| serialized_record.deserialize(serializer) }
       end
       BatchEnumerator.new(spec.batch_size, serialized_records.size, batch_reader).each
     elsif spec.first?
       serialized_records.first&.deserialize(serializer)
     elsif spec.last?
       serialized_records.last&.deserialize(serializer)
     else
       Enumerator.new do |y|
         serialized_records.each do |serialized_record|
           y << serialized_record.deserialize(serializer)
         end
       end
     end
   end
   ```

## Scheduler

- take serializer as an argument in `initialize`

- serialize records before scheduling with `RubyEventStore::Record#serialize` 

  ```ruby
  module RailsEventStore
    class ActiveJobScheduler
      def initialize(serializer:)
        @serializer = serializer
      end
   
      def call(klass, record)
        klass.perform_later(record.serialize(@serializer).to_h)
      end
    end
  end
  ```
  

## AsyncHandler

- pass `serializer:` to `event_store.deserialize`

  Either directly:

  ```ruby
  class SendOrderEmail < ActiveJob::Base
    def perform(payload)
      event = event_store.deserialize(**payload, serializer: ...)
  
      email = event.data.fetch(:customer_email)
      OrderMailer.notify_customer(email).deliver_now!
    end
  end
  ```
  
  Or via `RailsEventStore::AsyncHandler.with` module:
  
  ```ruby
  class SendOrderEmail < ActiveJob::Base
    prepend RailsEventStore::AsyncHandler.with(serializer: ...)
  
    def perform(event)
      email = event.data.fetch(:customer_email)
      OrderMailer.notify_customer(email).deliver_now!
    end
  end 
  ```
  

## Mapper

### PipelineMapper

- remove `RubyEventStore::Mappers::Transformation::Serialization.new(serializer: serializer)` transformation step from your pipeline in `RubyEventStore::Mappers::PipelineMapper`

- inline `RubyEventStore::Mappers::Pipeline.new(transformations: transformations)` to `RubyEventStore::Mappers::Pipeline.new(*transformations)`

- replace `RubyEventStore::Mappers::Transformation::Item` with `RubyEventStore::Record`

### Mapper

- rename `event_to_serialized_record` to `event_to_record`

- rename `serialized_record_to_event` to `record_to_event`

- replace `RubyEventStore::SerializedRecord` with `RubyEventStore::Record`, `timestamp` and `valid_at` attributes are of `Time` kind

