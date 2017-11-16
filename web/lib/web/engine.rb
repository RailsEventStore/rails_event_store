module Web
  class Engine < ::Rails::Engine
    isolate_namespace Web
  end
end
