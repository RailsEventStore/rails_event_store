FROM circleci/ruby:2.5.3-node-browsers
RUN  mkdir /res && chown circleci:circleci /res
USER circleci
