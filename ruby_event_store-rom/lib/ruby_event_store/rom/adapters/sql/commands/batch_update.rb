module RubyEventStore
  module ROM
    module SQL
      module Commands
        class BatchUpdate < ::ROM::Commands::Update[:sql]
          register_as :batch_update
          relation :events

          def execute(tuples)
            dataset = relation.dataset.unfiltered

            statements = Array([tuples]).flatten.map do |params|
              attributes = input[params].to_h.delete_if { |k, v| k == :created_at && v.nil? }
              id = attributes.delete(primary_key)
              dataset.where(primary_key => id).update_sql(attributes)
            end

            dataset.db[statements.join(";\n")].update

            tuples.to_a
          end
        end
      end
    end
  end
end
