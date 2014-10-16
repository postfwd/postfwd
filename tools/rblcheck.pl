#!/usr/bin/perl -T -w

# includes
use strict;
use warnings;
use Getopt::Long 2.25 qw(:config no_ignore_case bundling);
use Net::DNS;
# include Time::HiRes if available
BEGIN {
	eval { require Time::HiRes };
	Time::HiRes->import( qw(time) ) unless $@;
};

# RBLs (ip based)
our @rbls = qw(
        zz.countries.nerd.dk
        query.bondedsender.org
        exemptions.ahbl.org
        spf.trusted-forwarder.org
        list.dnswl.org
        zen.spamhaus.org
        b.barracudacentral.org
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
	t1.dnsbl.net.au
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
	sip.invaluement.com
);

# RHSBLs (domain based)
our @rhsbls = qw(
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

# commandline syntax
our $syntax = <<__SYNTAX__;
Usage:	rblcheck3.pl [OPTIONS] <objects>

	-h, --help		manual
	-s, --short		short output
	-v, --verbose		show dns nxdomain answers (not listed)
	-n, --noerror		do not show dns query timeouts
	-t, --timeout=10	dns query timeout setting in seconds
	    --dnsstats		show dns statistics
	    --rbls=<list>	override builtin rbls with <list>
	    --rhsbls=<list>	override builtin rhsbls with <list>

	<objects>	list of ips, hostnames and e-mail addresses
__SYNTAX__

# manual
our $examples = <<__EXAMPLES__;
Examples:

	# check builtin rbls for 192.168.0.1 and rhsbls for host.example.com
	rblcheck3.pl 192.168.0.1 host.example.com

	# same as above
	rblcheck3.pl host.example.com[192.168.0.1]

	# check builtin rhsbls for the domain part "example.com",
	# set dns timeout to 15 seconds
	rblcheck3.pl -t 15 john.doe\@example.com

	# check spamhaus and spamcop for 192.168.0.1
	# short output without dns timeout information
	rblcheck3.pl -ns --rbls=zen.spamhaus.org,bl.spamcop.net 192.168.0.1
__EXAMPLES__

# save current time
our $starttime = time();

# variables
use vars qw(
	%dnshits %dnscache %options
	@queries @lookups @timedout
);

# parse commandline switches
GetOptions( \%options,
	"timeout|t=i",
	"noerror|n",
	"verbose|v",
	"short|s+",
	"dnsstats",
	"rbls|rbl=s"	 => sub { push @{$options{rbls}},   (split /[,\s]+/, $_[1]) },
	"rhsbls|rhsbl=s" => sub { push @{$options{rhsbls}}, (split /[,\s]+/, $_[1]) },
	"help|h"	 => sub { print "\n$syntax\n$examples\n"; exit(1) },
) or die "\n$syntax\n";

# unbuffered output
#select STDERR; $| = 1;
#select STDOUT; $| = 1;

# optional: override dnsbl lists
@rbls   = @{$options{rbls}}   if defined $options{rbls};
@rhsbls = @{$options{rhsbls}} if defined $options{rhsbls};

# split client[ip] in two queries
map { push @queries, (/^([^\]]+)\[(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\]$/) ? ($1, $2) : $_ } @ARGV;

# parse queries and create lookup list
foreach my $query (@queries) {
	undef my $addr;

	# prepare rbls
	if ($query =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
		$addr = join ".", reverse split /\./, $query;
		foreach my $rbl (@rbls) {
			$dnscache{$addr.".".$rbl}{type}  = 'RBL';
			$dnscache{$addr.".".$rbl}{query} = $query;
			$dnscache{$addr.".".$rbl}{list}  = $rbl;
			push @lookups, $addr.".".$rbl;
		};
	# prepare rhsbls
	} else {
		# remove localpart if email address
		$addr = ($query =~ /@([^@]+)$/) ? $1 : $query;
		foreach my $rbl (@rhsbls) {
			$dnscache{$addr.".".$rbl}{type}  = 'RHSBL';
			$dnscache{$addr.".".$rbl}{query} = $query;
			$dnscache{$addr.".".$rbl}{list}  = $rbl;
			push @lookups, $addr.".".$rbl;
		};
	};
};

# main: process lookups
if ( @lookups ) {
	my $ownres   = Net::DNS::Resolver->new;
	my $ownsel   = IO::Select->new;
	my %ownsock  = ();
	my @ownready = ();
	my $bgsock   = undef;

	# send queries
	QUERY: foreach my $query (@lookups) {
		next QUERY unless $query;
		# send A query
		$dnscache{$query}{start} = time();
		$bgsock = $ownres->bgsend($query, 'A');
		$ownsel->add($bgsock);
		$ownsock{$bgsock} = 'A:'.$query;
		# send TXT query
		$bgsock = $ownres->bgsend($query, 'TXT');
		$ownsel->add($bgsock);
		$ownsock{$bgsock} = 'TXT:'.$query;
	};

	# get answers
        while ((scalar keys %ownsock) and (@ownready = $ownsel->can_read($options{timeout} || 10))) {
                foreach my $sock (@ownready) {
                        if (defined $ownsock{$sock}) {
                                my $packet = $ownres->bgread($sock);
                                rbl_read_dns ($packet);
                                delete $ownsock{$sock};
                        } else {
                                $ownsel->remove($sock);
                                $sock = undef;
                        };
                };
        };

	# timeout handling
	my $now = time();
	map { push @timedout, (split ':', $ownsock{$_})[1] } (keys %ownsock);
	map { @{$dnscache{$_}{A}} = '**timeout**'; $dnscache{$_}{end} = $now; delete $dnscache{$_}{log} } (sort @timedout) if @timedout;

	# print results
	map {	# timeout
		unless (defined $dnscache{$_}{log}) {
			$dnshits{timeouts}{$dnscache{$_}{list}}++;
			show_dns ($_) unless $options{noerror};
		# a-record
		} elsif ($dnscache{$_}{log}) {
			$dnshits{hits}{$dnscache{$_}{list}}++;
			show_dns ($_);
		# nxdomain
		} else {
			$dnshits{nxdomain}{$dnscache{$_}{list}}++;
			show_dns ($_) if $options{verbose};
		};
	} @lookups;
	printf STDOUT "\n # Finished %d lookups (%d items, %d rbls, %d rhsbls, %.1f%% timeouts) after %.2f seconds\n",
		($#lookups + 1),
		($#queries + 1),
		($#rbls + 1), ($#rhsbls + 1),
		(($#timedout + 1) / (($#lookups + 1) * 2)) * 100,
		(time() - $starttime) unless defined $options{short};
	if ($options{verbose} or $options{dnsstats}) {
		printf "\n # DNS statistics\n";
		if (defined $dnshits{hits}) {
			print " #\n";
			map { printf STDOUT " # ".$dnshits{hits}{$_}." hits for $_\n" } (sort {($dnshits{hits}{$b} || 0) <=> ($dnshits{hits}{$a} || 0)} keys %{$dnshits{hits}});
		};
		if (defined $dnshits{timeouts}) {
			print " #\n";
			map { printf STDOUT " # ".$dnshits{timeouts}{$_}." timeouts for $_\n" } (sort {($dnshits{timeouts}{$b} || 0) <=> ($dnshits{timeouts}{$a} || 0)} keys %{$dnshits{timeouts}});
		};
	};
	print "\n";
};
exit(0);

# prints DNS result
sub show_dns {
	my $que = shift;
	my $out = "";
	if (defined $options{short}) {
		$out .= $dnscache{$que}{query}
			."; ".$dnscache{$que}{list}
			."; ".(join ', ', @{$dnscache{$que}{A}});
		$out .=  "; ".(join '. ', @{$dnscache{$que}{TXT}}) if defined $dnscache{$que}{TXT} and ($options{verbose} or ($options{short} < 2));
	} else {
		$out .= "\n  ".sprintf ("%15s", $dnscache{$que}{query})."  ".$dnscache{$que}{type}.": ".$dnscache{$que}{list};
		$out .= "  (cname: ".(join ', ', (keys %{$dnscache{$que}{CNAME}})).")" if defined $dnscache{$que}{CNAME};
		$out .= "\n  ".sprintf ("%15s", $dnscache{$que}{query})."  ".(join ', ', @{$dnscache{$que}{A}});
		$out .= "  (time: ".sprintf ("%.1fs)", ($dnscache{$que}{end} - $dnscache{$que}{start}));
		$out .= "  (ttl: ".$dnscache{$que}{ttl}."s)" if defined $dnscache{$que}{ttl};
		$out .= "\n  ".sprintf ("%15s", $dnscache{$que}{query})."  ".(join '. ', @{$dnscache{$que}{TXT}}) if defined $dnscache{$que}{TXT};
	};
	print STDOUT "$out\n";
};

# reads DNS answer
sub rbl_read_dns {
    my($myresult) = shift;
    my($now)      = time();
    my($que,$typ) = undef;

    if ( defined $myresult ) {
        # read question, for dns cache id
        foreach ($myresult->question) {
                $typ = ($_->qtype || '') unless $typ;
		$que = ($_->qname || '') unless $que;
	};
        # not listed
	unless ($myresult->answer) {
		@{$dnscache{$que}{A}} = '<nxdomain>';
		$dnscache{$que}{end} = $now;
		$dnscache{$que}{log} = 0;
        # parse answers
	} else {
	        foreach ($myresult->answer) {
                        if ($_->type =~ /^(A|CNAME|TXT)$/) {
                        	if ($_->type eq 'A') {
                	                push @{$dnscache{$que}{A}}, ($_->address || '');
				} elsif ($_->type eq 'TXT') {
                                	my $res = (join(' ', $_->char_str_list()) || '');
	               	                push @{$dnscache{$que}{TXT}}, $res if $res;
				} elsif ($_->type eq 'CNAME') {
                	                $dnscache{$que}{CNAME}{$_->cname} = 1 if $_->cname;
				};
                       	        $dnscache{$que}{ttl} = ($_->ttl || 0) unless defined $dnscache{$que}{ttl};
				$dnscache{$que}{end} = $now;
				$dnscache{$que}{log} = 1;
			} else {
				print STDERR "IGNORING query: $que, TYPE: '".($_->type || '')."'\n";
			};
		};
	};
    };
};

