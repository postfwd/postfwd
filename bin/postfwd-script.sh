#!/bin/sh
#
# Startscript for the postfwd daemon
#
# by JPK

PATH=/bin:/usr/bin:/usr/local/bin

# path to program
PFWCMD=/usr/local/postfwd/sbin/postfwd
# rulesetconfig file
PFWCFG=/etc/postfix/postfwd.cf
# pidfile
PFWPID=/var/tmp/postfwd.pid

# daemon settings
PFWUSER=nobody
PFWGROUP=nobody
PFWINET=127.0.0.1
PFWPORT=10040

# recommended extra arguments
PFWARG="--shortlog --summary=600 --cache=600 --cache-rbl-timeout=3600 --cleanup-requests=1200 --cleanup-rbls=1800 --cleanup-rates=1200"


## should be no need to change below

P1="`basename ${PFWCMD}`"
case "$1" in

	start*)		echo "Starting ${P1}...";
			${PFWCMD} ${PFWARG} --daemon --file=${PFWCFG} --interface=${PFWINET} --port=${PFWPORT} --user=${PFWUSER} --group=${PFWGROUP} --pidfile=${PFWPID};
			;;

	debug*)		echo "Starting ${P1} in debug mode...";
			${PFWCMD} ${PFWARG} -vv --daemon --file=${PFWCFG} --interface=${PFWINET} --port=${PFWPORT} --user=${PFWUSER} --group=${PFWGROUP} --pidfile=${PFWPID};
			;;

	stop*)		${PFWCMD} --interface=${PFWINET} --port=${PFWPORT} --pidfile=${PFWPID} --kill;
			;;

	reload*)	${PFWCMD} --interface=${PFWINET} --port=${PFWPORT} --pidfile=${PFWPID} -- reload;
			;;

	restart*)	$0 stop;
			sleep 4;
			$0 start;
			;;

	*)		echo "Unknown argument \"$1\"" >&2;
			echo "Usage: `basename $0` {start|stop|debug|reload|restart}" >&2;
			exit 1;;
esac
exit $?
