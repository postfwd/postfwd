#
# Dockerfile for DockerHub automatic build of postfwd - http://postfwd.org/docker
#
# If you want to rebuild it, go to the top directory (usually 'cd ..') and type in:
#
#	docker build -f docker/Dockerfile-autobuild -t postfwd:mybuild .
#
# To run a container from it, use:
#
#	docker run -it postfwd:mybuild
#
# or with more options (postfwd2 on port 10050, postfwd.cf in /path/to/ruleset):
#
#	docker run -it -e PROG=postfwd2 -e PORT=10050 -v /path/to/ruleset:/etc/postfwd:ro postfwd:mybuild
#
FROM alpine:latest

LABEL maintainer="Postfwd Docker - http://postfwd.org/docker"

##
## RUNTIME ARGS
##
# use 'postfwd1' or 'postfwd2' to switch between versions
# go to http://postfwd.org/versions.html for more info
ENV PROG=postfwd1
# port for postfwd
ENV PORT=10040
# request cache in seconds. use '0' to disable
ENV CACHE=60
# additional arguments, see postfwd -h or man page for more
ENV EXTRA="--summary=600 --noidlestats"
# get config file from ARG
ENV CONF=postfwd.cf

##
## CONTAINER ARGS
##
# configuration directory
ENV ETC=/etc/postfwd
# target for postfwd distribution
ENV TARGET=/usr
# data directory
ENV HOME=/var/lib/postfwd
# user and group for execution
ENV USER=postfw
ENV GROUP=postfw
ENV UID=110
ENV GID=110

# install stuff
RUN apk update && apk add \
	perl \
	perl-net-dns \
	perl-net-server \
	perl-netaddr-ip \
	perl-net-cidr-lite \
	perl-time-hires \
	perl-io-multiplex
	
# create stuff
RUN addgroup -S -g ${GID} ${GROUP}
RUN adduser -S -u ${UID} -D -H -G ${GROUP} -h ${HOME} -s /bin/false ${USER}
RUN mkdir -p ${ETC} ${HOME}

# copy stuff
COPY ./etc/	${ETC}/
COPY ./sbin/    ${TARGET}/sbin/
COPY ./docker/postfwd-docker.sh /usr/bin/postfwd-docker

# set ownership & permissions
RUN chown -R root:${GID} ${ETC} && chmod 0750 ${ETC} && chmod 0640 ${ETC}/*
RUN chown -R ${UID}:${GID} ${HOME} && chmod -R 0700 ${HOME}
RUN chown root:root ${TARGET}/sbin/postfwd* /usr/bin/postfwd-docker && chmod 0755 ${TARGET}/sbin/postfwd* /usr/bin/postfwd-docker

# open port
EXPOSE ${PORT}

# start postfwd - don't worry about versions: postfwd1 will silently ignore postfwd2-specific arguments
ENTRYPOINT exec ${TARGET}/sbin/${PROG} --file=${ETC}/${CONF} --user=${USER} --group=${GROUP} \
	--server_socket=tcp:0.0.0.0:${PORT} --cache_socket=unix::${HOME}/postfwd.cache \
	--pidfile=${HOME}/postfwd.pid --save_rates=${HOME}/postfwd.rates --save_groups=${HOME}/postfwd.groups \
	--cache=${CACHE} ${EXTRA} \
	--stdout --nodaemon

