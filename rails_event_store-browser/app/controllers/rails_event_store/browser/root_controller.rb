module RailsEventStore
  module Browser
    class RootController < ApplicationController
      def welcome
        render :welcome, layout: false
      end
    end
  end
end