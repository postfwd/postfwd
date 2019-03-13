#!/bin/sh
#
# Small helper script to run commands in the container without the
# need to specify all arguments to communication with the daemon:
#
#	docker run -it <container-name> postfwd-docker reload
#	  or
#	docker run -it <container-name> postfwd-docker dumpcache
#

PATH=/usr/sbin:/usr/bin:/sbin:/bin

[ -z "$1" ] && {
	echo
	echo "ERROR: Not enough arguments!"
	echo "       Use -h for a list of options."
	echo
	exit 1
} >&2

case "$1" in

	show)	echo COMMANDLINE=${TARGET}/sbin/${PROG} --file=${ETC}/${CONF} --user=${USER} --group=${GROUP} \
			--server_socket=tcp:0.0.0.0:${PORT} --cache_socket=unix::${HOME}/postfwd.cache \
			--pidfile=${HOME}/postfwd.pid --save_rates=${HOME}/postfwd.rates --save_groups=${HOME}/postfwd.groups \
			--cache=${CACHE} ${EXTRA} \
			--stdout --nodaemon
		exit
		;;

	*)	${TARGET}/sbin/${PROG} --file=${ETC}/${CONF} --user=${USER} --group=${GROUP} \
			--server_socket=tcp:0.0.0.0:${PORT} --cache_socket=unix::${HOME}/postfwd.cache \
			--pidfile=${HOME}/postfwd.pid --save_rates=${HOME}/postfwd.rates --save_groups=${HOME}/postfwd.groups \
			--cache=${CACHE} ${EXTRA} \
			--stdout --nodaemon $@

esac

