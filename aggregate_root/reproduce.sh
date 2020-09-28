#!/bin/sh -ex

bundle info mutant
bundle info mutant-rspec
ruby -v
uname -v
bundle exec mutant --use rspec --require aggregate_root AggregateRoot.included
