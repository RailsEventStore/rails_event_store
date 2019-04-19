FROM circleci/ruby:2.4-node-browsers
USER root
RUN echo "deb http://deb.debian.org/debian stretch-backports main" > /etc/apt/sources.list.d/stretch-backports.list && \
	apt-get update && \
	apt-get -y -t stretch-backports install libsqlite3-dev
