module AggregateRoot
  module DefaultApplyStrategy
    def inject_apply_strategy!(event)
      {
        event.class => method("apply_#{event.class.name.underscore.gsub('/', '_')}")
      }
    end
  end
end
