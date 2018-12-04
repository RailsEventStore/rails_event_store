FROM circleci/ruby:2.5.3-node-browsers
RUN sudo mkdir /res && sudo chown circleci:circleci /res
USER circleci
