module RailsEventStore
  module RSpec
    module Matchers
      class EnglishPhrasing
        def self.list(object)
          return format(object) if !object || Struct === object
          items = Array(object).map { |o| format(o) }
          case items.length
          when 0
            ""
          when 1
            items[0]
          when 2
            items.join(" and ")
          else
            "#{items[0...-1].join(', ')} and #{items[-1]}"
          end
        end

        private

        def self.format(object)
          if object.respond_to?(:description)
            ::RSpec::Support::ObjectFormatter.format(object)
          else
            "be a #{object}"
          end
        end
      end

      def be_an_event(expected)
        BeEvent.new(expected, differ: differ, formatter: formatter)
      end
      alias :be_event :be_an_event
      alias :an_event :be_an_event
      alias :event    :be_an_event

      def have_published(*expected)
        HavePublished.new(*expected, differ: differ, phraser: phraser)
      end

      def have_applied(*expected)
        HaveApplied.new(*expected, differ: differ, phraser: phraser)
      end

      private

      def formatter
        ::RSpec::Support::ObjectFormatter.public_method(:format)
      end

      def differ
        ::RSpec::Support::Differ.new(color: ::RSpec::Matchers.configuration.color?)
      end

      def phraser
        EnglishPhrasing.public_method(:list)
      end
    end
  end
end
