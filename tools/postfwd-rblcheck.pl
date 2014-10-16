#!/usr/bin/perl -T -w
#
# Tool to query a bunch of dnsbls. Usage:
#
#	postfwd-rblcheck.pl <hostname or ip> [<hostname or ip> ...]
#
# by JPK


use Net::DNS::Async;
use strict;

# length of screen
my $mylen = 79;

# RBLs (ip based)
my @rbls = qw(
        query.bondedsender.org
        exemptions.ahbl.org
        spf.trusted-forwarder.org
        list.dnswl.org
        zz.countries.nerd.dk
        zen.spamhaus.org
        bl.spamcop.net
        list.dsbl.org
        multihop.dsbl.org
        unconfirmed.dsbl.org
        combined.njabl.org
        dnsbl.sorbs.net
        dnsbl.ahbl.org
        ix.dnsbl.manitu.net
        dnsbl-1.uceprotect.net
        dnsbl-2.uceprotect.net
        dnsbl-3.uceprotect.net
        ips.backscatterer.org
        sorbs.dnsbl.net.au
        korea.services.net
        blackholes.five-ten-sg.com
        cbl.anti-spam.org.cn
        cblplus.anti-spam.org.cn
        cblless.anti-spam.org.cn
        bogons.cymru.com
        dynamic.tqmrbl.com
        relays.tqmrbl.com
        clients.tqmrbl.com
	hostkarma.junkemailfilter.com
);

# RHSBLs (domain based)
my @rhsbls = qw(
	rhsbl.sorbs.net
	rhsbl.ahbl.org
	multi.surbl.org
	dsn.rfc-ignorant.org
	abuse.rfc-ignorant.org
	whois.rfc-ignorant.org
	bogusmx.rfc-ignorant.org
	blackhole.securitysage.com
	ex.dnsbl.org
	rddn.dnsbl.net.au
	block.rhs.mailpolice.com
	dynamic.rhs.mailpolice.com
	dnsbl.cyberlogic.net
	hostkarma.junkemailfilter.com
);

# async dns object
my $DNS = new Net::DNS::Async ( QueueSize => 100, Retries => 3, Timeout => 20 );
our %RBLres = ();

# async dns callback method
sub callback {
    my $myresponse = shift;
    my $query = ''; my $result = '';

	# get query
	if ( defined $myresponse ) {
		foreach ($myresponse->question) {
       		 	next unless (($_->qtype eq 'A') or ($_->qtype eq 'TXT'));
			$query = $_->qname;
		};
	
		# get answer and fill result hash
		if ( defined $query ) {
			foreach ($myresponse->answer) {
				if ($_->type eq 'A') {
					$result = $_->address;
			        	$query ||= ''; $result ||= '';
					$RBLres{$query}{result} = $result;
					$RBLres{$query}{end} = time;
				} elsif ($_->type eq 'TXT') {
					$RBLres{$query}{text} = join(" ", $_->char_str_list());
					$RBLres{$query}{end} = time;
				};
			};
		};
	};
};

# main, parse argument list
foreach (@ARGV) {
    my $query = $_;
    my $now = time;
    my @lookups = ();
    my $name  = my $addr = my $res = 'unknown';
    my $rblcount = my $rhlcount = 0;

	# clear result hash
	%RBLres = ();

	# lookup hostname or ip address, remove localpart if email address
	if ($query =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
		$addr = $query;
		$name = $res
			if ( defined($res = gethostbyaddr (pack ('C4', (split /\./, $addr)), 2)) );
	} else {
		$name = ($query =~ /@([^@]+)$/) ? $1 : $query;
		$addr = ( join ".", (unpack ('C4', $res)) )
			if ( defined ($res = gethostbyname ($name.".")) );
	};

	# header
	print "\n", "=" x $mylen, "\n";
	print "QUERY: ", $query, "  NAME: ", $name, "  ADDR: ", $addr, "\n";

	# prepare rbl lookups
	unless ($addr eq 'unknown') {
		$addr = join ".", reverse split /\./, $addr;
		foreach my $rbl (@rbls) {
			$RBLres{$addr.".".$rbl}{query} = $rbl;
			$RBLres{$addr.".".$rbl}{type}  = 'RBL';
			$RBLres{$addr.".".$rbl}{start} = time;
			push @lookups, $addr.".".$rbl;
			#print "query ", $RBLres{$addr.".".$rbl}{query}, " for ", $addr.".".$rbl, "\n";
		};
	};

	# prepare rhsbl lookups
	unless ($name eq 'unknown') {
		foreach my $rhsbl (@rhsbls) {
			$RBLres{$name.".".$rhsbl}{query} = $rhsbl;
			$RBLres{$name.".".$rhsbl}{type}  = 'RHSBL';
			$RBLres{$name.".".$rhsbl}{start} = time;
			push @lookups, $name.".".$rhsbl;
			#print "name ", $RBLres{$name.".".$rhsbl}{query}, " for ", $name.".".$rhsbl, "\n";
		};
	};

	# perform lookups
	map { $DNS->add (\&callback, $_) } @lookups; 
	map { $DNS->add (\&callback, $_, 'TXT') } @lookups; 
	$DNS->await();

	# evaluate results
	foreach $query (sort keys %RBLres) {
		if ($query and (defined $RBLres{$query}{result})) {
			print "  ", "-" x ($mylen - 4), "\n";
			printf "  listed on %s:%s, result: %s, time: %ds\n  %s\n",
				$RBLres{$query}{type},
				$RBLres{$query}{query}, $RBLres{$query}{result},
				($RBLres{$query}{end} - $RBLres{$query}{start}),
				((defined $RBLres{$query}{text}) ? "\"".$RBLres{$query}{text}."\"" : '<undef>');
			$rblcount++ if $RBLres{$query}{type} eq 'RBL';
			$rhlcount++ if $RBLres{$query}{type} eq 'RHSBL';
		};
	};

	# footer
	print "  ", "-" x ($mylen - 4), "\n";
	printf "%d of %d RBLs, ", $rblcount, $#rbls if ($rblcount > 0);
	printf "%d of %d RHSBLs, ", $rhlcount, $#rhsbls if ($rhlcount > 0);
	printf "Finished after %d seconds\n", (time - $now);
	print "=" x $mylen, "\n\n";
};
