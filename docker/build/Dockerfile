FROM debian:stretch-slim

LABEL maintainer="Postfwd Docker Testing - http://postfwd.org/docker"

## BUILD ARGS
# GitHub postfwd branch (currently needs 'testing' for docker)
ARG BRANCH=testing

## RUNTIME ARGS
# use 'postfwd1' or 'postfwd2' to switch between versions
# go to http://postfwd.org/versions.html for more info
ENV PROG=postfwd1
# port for postfwd
ENV PORT=10040
# name of config file
ENV CONF=postfwd.cf
# request cache in seconds. use '0' to disable
ENV CACHE=0
# additional arguments, see postfwd -h or man page for more
ENV EXTRA="--no_parent_dns_cache --noidlestats"

# install stuff
RUN apt-get update && apt-get install -y git postfwd
RUN git clone https://github.com/postfwd/postfwd --branch ${BRANCH} --single-branch /opt/postfwd

# create stuff
RUN mkdir -p /etc/postfwd && chown root:postfw /etc/postfwd && chmod 0750 /etc/postfwd
RUN mkdir -p /var/lib/postfwd && chown postfw:postfw /var/lib/postfwd && chmod 0700 /var/lib/postfwd
COPY ${CONF} /etc/postfwd/${CONF}

# open port
EXPOSE ${PORT}

# start postfwd - don't worry about versions: postfwd1 will silently ignore postfwd2-specific arguments
ENTRYPOINT exec /opt/postfwd/sbin/${PROG} --file /etc/postfwd/${CONF} --user postfw --group postfw \
	--server_socket tcp:0.0.0.0:${PORT} --cache_socket=unix::/var/lib/postfwd/postfwd.cache \
	--pidfile=/var/lib/postfwd/postfwd.pid --save_rates=/var/lib/postfwd/postfwd.rates \
	--cache=${CACHE} ${EXTRA} \
	--stdout --nodaemon

