Directory contents:

-	rblcheck.pl <ip- or email-address> <ip- or email-address>, ...
	Get RBL (Realtime Blackhole Lists) information without using Socket.pm

-	pcrecheck.pl <string> <pattern>
	simple PCRE (perl compatible regular expression) testscript

-	bench.sh [-q] <command>
	uses the time command to measure a program's running time
	in milliseconds

-	lograte.sh [OPTIONS] <logfile>
	generates per minute stats for generic syslog files

-	request.sample
	a sample policy delegation request. you may test your postfwd config with
 	  postfwd -f <configfile> request.sample

by JPK
