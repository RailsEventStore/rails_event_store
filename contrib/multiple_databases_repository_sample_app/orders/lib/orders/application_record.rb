require 'active_record'

module Orders
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    connects_to database: { writing: :orders, reading: :orders }
  end
end
