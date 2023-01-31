class RedisClient
  class Config
    prepend(
      Module.new do
        def initialize(url: nil, **kwargs)
          uri = URI.parse(url)
          if uri.scheme == "unix"
            super(**kwargs, url: nil)
            @path = uri.path
          else
            super
          end
        end
      end
    )
  end
end