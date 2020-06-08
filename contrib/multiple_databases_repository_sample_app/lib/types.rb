require 'dry-types'

module Types
  ID            = Types::Strict::Integer
  UUID          = Types::Strict::String.constrained(format: /\A[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}\z/i)
  TransactionId = Types::Strict::String.constrained(format: /\A[0-9a-fA-F]{32}\z/i)
  OrderNumber   = Types::Strict::String.constrained(format: /\A\d{4}\/\d{2}\/\d+\z/i)
end
