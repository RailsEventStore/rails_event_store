module RailsEventStore
  module Browser
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
