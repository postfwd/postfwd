#!/usr/local/bin/perl
#
# simple PCRE (perl compatible regular expression) testscript
# call it
#
#	pcrecheck.pl <string> <pattern>
#
# by JPK

$wert = $ARGV[0];
$mask = $ARGV[1];

if ( $wert =~ /($mask)/ ) {
	print "Wert: $wert, Mask: $mask, Match \$1: $1\n";
}
