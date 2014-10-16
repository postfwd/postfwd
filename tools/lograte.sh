#!/bin/sh
#
# generates per minute stats for generic syslog files
# call it:
#
#	lograte.sh [OPTIONS] <logfile>
#
# or for online monitoring
#
#	tail -f <logfile> | lograte.sh [OPTIONS]
#
# by JPK

PATH=/usr/local/bin:/bin:/usr/bin

# default values
PATTERN=".*"
MINIMUM=1
TOPLIST=10

# show usage
Usage () {
	{
		echo "Usage:   `basename $0` -m <mincount> -t <topcount> -s <filter> <file> <file> ...";
		echo "	-m 	minimum events to display"
		echo "	-t 	how many rankings?"
		echo "	-T 	print rankings only"
		echo "	-s 	filter input through this regexp"
		echo "Example: `basename $0` -m 10 -t 5 -s \"(panic|error)\" /var/log/messages"
	} >&2
}

# parse arguments
while getopts Tt:m:s: o
do	case "$o" in
	s)	PATTERN="$OPTARG";;
	m)	MINIMUM="$OPTARG";;
	t)	TOPLIST="$OPTARG";;
	T)	TOPONLY=1;;
	*)	Usage;
		exit 1;;
	esac
done
shift `expr $OPTIND - 1`

# a single awk
awk '	($0 ~ PATTERN) {
		split($3,TIME,":");
		CURRTIME=$1 " " $2 " " TIME[1] ":" TIME[2];
		if (LASTTIME != CURRTIME) {
			if (COUNT >= MINIMUM) {
				if (!(TOPONLY == 1)) {
					printf ( "%s %7d events, %8.2f per sec\n", LASTTIME, COUNT, ( COUNT / 60 ) );
				};
				for (i=1;i<=TOPLIST;i++) {
					if (COUNT > MAXCOUNT[i]) {
						MAXCOUNT[i+1]=MAXCOUNT[i];
						MAXCOUNT[i]=COUNT;
						MAXTIME[i+1]=MAXTIME[i];
						MAXTIME[i]=LASTTIME;
						break;
					};
				};
			};
			COUNT=1;
		} else {
			COUNT++;
		};
		LASTTIME=CURRTIME;
	}

	END {
		if (CURRTIME != "") {
			if ( (COUNT >= MINIMUM) && (!(TOPONLY == 1)) ) {
				printf ( "%s %7d events, %8.2f per sec\n\n", LASTTIME, COUNT, ( COUNT / 60 ) );
			};
			print "###########";
			printf ("# TOP %3d #\n",TOPLIST);
			print "###########";
			for (i=1;i<=TOPLIST;i++) {
				printf ( "# TOP %3d:\t%s %7d events, %8.2f per sec\n", i, MAXTIME[i], MAXCOUNT[i], ( MAXCOUNT[i] / 60 ) );;
			};
			exit 0;
		} else {
			exit 1;
		};
	}' PATTERN="${PATTERN}" MINIMUM="${MINIMUM}" TOPLIST="${TOPLIST}" TOPONLY="${TOPONLY}" $*

# set exitcode=1 if no matching lines found
exit $?
