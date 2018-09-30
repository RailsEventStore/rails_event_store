module RubyEventStore
  module ROM
    module Memory
      module Commands
        class BatchUpdate < ::ROM::Commands::Update[:memory]
          register_as :batch_update
          relation :events

          def execute(tuples)
            Array([tuples]).flatten.each do |params|
              attributes = input[params].to_h.delete_if { |k, v| k == :created_at && v.nil? }
              relation.by_pk(params.fetch(:id)).dataset.map { |tuple| tuple.update(attributes) }
            end
          end
        end
      end
    end
  end
end
