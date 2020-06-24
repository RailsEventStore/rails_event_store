FROM ruby:2.7
  ARG GEM_VERSION
  RUN gem install ruby_event_store-outbox --version $GEM_VERSION
  RUN gem install influxdb --version 0.8.0
  RUN gem install redis mysql2
  ENTRYPOINT ["/usr/local/bundle/bin/res_outbox"]
