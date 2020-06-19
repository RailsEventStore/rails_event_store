require 'active_record'

module Shipping
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    connects_to database: { writing: :shipping, reading: :shipping }
  end
end
