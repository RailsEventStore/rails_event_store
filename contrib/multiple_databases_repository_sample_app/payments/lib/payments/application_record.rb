module Payments
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    connects_to database: { writing: :payments, reading: :payments }
  end
end
