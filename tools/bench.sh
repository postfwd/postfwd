#!/bin/sh
#
# simple benchmark tool
#
# uses the time command to measure a program's running time
# in milliseconds. simply call it:
#
#      bench.sh [-q] <command>
#
# by JPK

# check for '-q' option
[ "$1" = '-q' ] && { QUIET=1; shift; }

# output temp file
FILE="/tmp/`basename $0`.$$"
[ -f ${FILE} ] && { echo "TEMP-File ${FILE} already exists - terminating" >&2; exit 1; }

# get command-line
CMD="$*"
[ -z "$CMD" ] && { echo "no command given" >&2; exit 1; }

# remove temp file on break
trap 'rm -f $FILE; exit 1' 1 2 15

# run command; recalculate output of 'time' command
ZEIT=`( time $CMD >$FILE 2>&1 ) 2>&1 | awk 'FS="[.ms \t]" { if (/^real/) { print ( ($2 * 60000) + ($3 * 1000) + $4 ) } }'`

# display output on error
result=$?
[ "$result" -gt 0 ] && { echo "Exit-Code > 0. Output was:"; cat $FILE; }

# create verbose output
[ -z "$QUIET" ] && ZEIT="needed $ZEIT for command \"${CMD}\"\n"

# print result
printf "$ZEIT"

# clean up
rm -f $FILE

# exit with program's exit-code
exit $result
