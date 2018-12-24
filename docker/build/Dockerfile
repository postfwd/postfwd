FROM debian:stretch-slim

LABEL maintainer="Postfwd Docker Testing <http://postfwd.org>"

# use 'postfwd1' or 'postfwd2' to switch between versions
ARG PROG=postfwd2
# name of config file
ARG CONF=postfwd.cf
# port for postfwd
ARG PORT=10040
# request cache in seconds. use '0' to disable
ARG CACHE=600

# install stuff
RUN apt-get update && apt-get install -y \
## TESTING: remove wget after release!
	wget \
	postfwd

# ARG2ENV - ugly - still have to get deeper into Dockerfile syntax - assistance welcome ;)
ENV POSTFWD_PROG=${PROG}
ENV POSTFWD_CONF=${CONF}
ENV POSTFWD_PORT=${PORT}
ENV POSTFWD_CACHE=${CACHE}

# create stuff
RUN mkdir -p /etc/postfwd && chown root:postfw /etc/postfwd && chmod 0750 /etc/postfwd
RUN mkdir -p /var/lib/postfwd && chown postfw:postfw /var/lib/postfwd && chmod 0700 /var/lib/postfwd
COPY ${POSTFWD_CONF} /etc/postfwd/${POSTFWD_CONF}
## TESTING: remove wget after release!
RUN wget -O /usr/sbin/${POSTFWD_PROG} http://postfwd.org/DEVEL/${POSTFWD_PROG}-1.36-devel1 && \
	chmod 0755 /usr/sbin/${POSTFWD_PROG} && ls -l /usr/sbin/${POSTFWD_PROG}

# open port
EXPOSE ${PORT}

# start postfwd - don't worry about versions: postfwd1 will silently ignore postfwd2-specific arguments
ENTRYPOINT /usr/sbin/${POSTFWD_PROG} --file /etc/postfwd/${POSTFWD_CONF} --user postfw --group postfw \
	--server_socket tcp:0.0.0.0:${POSTFWD_PORT} --cache_socket=unix::/var/lib/postfwd.cache \
	--pidfile=/var/lib/postfwd/postfwd.pid --save_rates=/var/lib/postfwd/postfwd.rates \
	--cache=${POSTFWD_CACHE} --no_parent_dns_cache \
	--stdout --nodaemon

