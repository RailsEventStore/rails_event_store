FROM ruby:2.5.3-alpine
RUN apk update && \
    apk add --no-cache \
	build-base \
        yarn \
        git \
        mysql-dev \
        postgresql-dev \
        mariadb-dev \
        sqlite-dev \
        ncurses
