#!/bin/sh

PATH=/usr/local/postfwd/bin:/usr/local/bin:/usr/bin:/bin

LOGFILE=/var/log/maillog
CHECK=countrycheck.pl

[ -n "$1" ] && LOGFILE="$1"

grep ' connect from' ${LOGFILE} | \
	awk '{FS="[\\[\\] ]"; print $11}' | \
	sort | uniq | \
	egrep -v "(unknown|127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)" | \
	xargs ${CHECK} | \
	awk '{FS=";"; print $3 " " $2}' | \
	sed 	's/^[ 	][ 	]*//g;
		 s/[ 	][ 	]*$//g;
		 /^[ 	]*$/d;' | \
	sort | \
	uniq -c | \
	sort -k1 -n

