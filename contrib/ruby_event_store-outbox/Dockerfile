FROM ruby:3.2
  ARG GEM_VERSION
  RUN gem install ruby_event_store-outbox --version $GEM_VERSION
  RUN gem install influxdb --version 0.8.1
  RUN gem install redis-client mysql2
  ENTRYPOINT ["/usr/local/bundle/bin/res_outbox"]
