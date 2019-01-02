#
# Sample Dockerfile for postfwd - http://postfwd.org/docker
#
# Edit postfwd.cf and use with:
#
#   docker build --pull --no-cache -t postfwd:testing .
#   docker run -v `pwd`/postfwd.cf:/etc/postfwd/postfwd.cf:ro -it postfwd:testing
#
# or with more options (postfwd2 on post 10050):
#
#   docker run -v `pwd`/ruleset:/etc/postfwd:ro -e PROG=postfwd2 -e PORT=10050 -it postfwd:testing
#
FROM debian:stretch-slim

LABEL maintainer="Postfwd Docker Testing - http://postfwd.org/docker"

##
## BUILD ARGS
##
# GitHub postfwd url
ARG URL=https://github.com/postfwd/postfwd
# GitHub postfwd branch (currently needs 'testing' for docker)
ARG BRANCH=testing

##
## RUNTIME ARGS
##
# use 'postfwd1' or 'postfwd2' to switch between versions
# go to http://postfwd.org/versions.html for more info
ENV PROG=postfwd1
# port for postfwd
ENV PORT=10040
# request cache in seconds. use '0' to disable
ENV CACHE=0
# additional arguments, see postfwd -h or man page for more
ENV EXTRA="--no_parent_dns_cache --noidlestats --summary=600"
# get config file from ARG
ENV CONF=postfwd.cf

##
## CONTAINER ARGS
##
# configuration directory
ENV ETC=/etc/postfwd
# target for postfwd distribution
ENV TARGET=/opt/postfwd
# data directory
ENV HOME=/var/lib/postfwd
# user and group for execution
ENV USER=postfw
ENV GROUP=postfw

# install stuff
RUN apt-get update && apt-get install --no-install-recommends -y \
    libnet-dns-perl libnet-server-perl \
    libtime-hires-perl libstorable-perl \
    git
RUN git clone ${URL} --branch ${BRANCH} --single-branch ${TARGET}
RUN apt-get purge -y --auto-remove git && apt-get autoremove -y && rm -fR /var/lib/apt/lists/*

# create stuff
RUN addgroup --quiet --system ${GROUP}
RUN adduser --quiet --system --no-create-home --disabled-login --disabled-password \
    --ingroup ${GROUP} --home ${HOME} --shell /bin/false ${USER}
RUN mkdir -p ${ETC} && chown root:${GROUP} ${ETC} && chmod 0750 ${ETC}
RUN mkdir -p ${HOME} && chown ${USER}:${GROUP} ${HOME} && chmod 0700 ${HOME}

# open port
EXPOSE ${PORT}

# start postfwd - don't worry about versions: postfwd1 will silently ignore postfwd2-specific arguments
ENTRYPOINT exec ${TARGET}/sbin/${PROG} --file ${ETC}/${CONF} --user ${USER} --group ${GROUP} \
	--server_socket tcp:0.0.0.0:${PORT} --cache_socket=unix::${HOME}/postfwd.cache \
	--pidfile=${HOME}/postfwd.pid --save_rates=${HOME}/postfwd.rates \
	--cache=${CACHE} ${EXTRA} \
	--stdout --nodaemon

