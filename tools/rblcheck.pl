#!/usr/local/bin/perl -T
#
# rblcheck.pl - Get RBL (Realtime Blackhole Lists) information without using Socket.pm
#
# USAGE: rblcheck.pl <ip- or email-address>, <ip- or email-address>, ...
#
# JPK

our (%RWLs) = (
        #
        # Name of Whitelist             => result-pattern (means "listed")
        #
        "query.bondedsender.org"        => '^127\.0\.0\.\d+$' ,
        "exemptions.ahbl.org"           => '^127\.0\.0\.\d+$' ,
        "spf.trusted-forwarder.org"     => '^127\.0\.0\.\d+$' ,
        "list.dnswl.org"                => '^127\.0\.0\.\d+$' ,
);

our (%RBLs) = (
        #
        # Name of RBL                   => result-pattern (means "listed")
        #
        "zen.spamhaus.org"              => '^127\.0\.0\.\d+$' ,
        "bl.spamcop.net"                => '^127\.0\.0\.\d+$' ,
        "list.dsbl.org"                 => '^127\.0\.0\.\d+$' ,
        "multihop.dsbl.org"             => '^127\.0\.0\.\d+$' ,
        "unconfirmed.dsbl.org"          => '^127\.0\.0\.\d+$' ,
        "combined.njabl.org"            => '^127\.0\.0\.\d+$' ,
        "dnsbl.sorbs.net"               => '^127\.0\.0\.\d+$' ,
        "dnsbl.ahbl.org"                => '^127\.0\.0\.\d+$' ,
        "ix.dnsbl.manitu.net"           => '^127\.0\.0\.\d+$' ,
        #
        # experimental
        "dnsbl-1.uceprotect.net"        => '^127\.0\.0\.\d+$' ,
        "dnsbl-2.uceprotect.net"        => '^127\.0\.0\.\d+$' ,
        "dnsbl-3.uceprotect.net"        => '^127\.0\.0\.\d+$' ,
        "ips.backscatterer.org"         => '^127\.0\.0\.\d+$' ,
        "sorbs.dnsbl.net.au"            => '^127\.0\.0\.\d+$' ,
        "korea.services.net"            => '^127\.0\.0\.\d+$' ,
        "blackholes.five-ten-sg.com"    => '^127\.0\.0\.\d+$' ,
        "cbl.anti-spam.org.cn"          => '^127\.0\.0\.\d+$' ,
        "cblplus.anti-spam.org.cn"      => '^127\.0\.0\.\d+$' ,
        "cblless.anti-spam.org.cn"      => '^127\.0\.0\.\d+$' ,
        "bogons.cymru.com"              => '^127\.0\.0\.\d+$' ,
);

our (%RHSBLs) = (
        #
        # Name of RHSBL                 => result-pattern (means "listed")
        #
        "rhsbl.sorbs.net"               => '^127\.0\.0\.\d+$' ,
        "rhsbl.ahbl.org"                => '^127\.0\.0\.\d+$' ,
        "multi.surbl.org"               => '^127\.0\.0\.\d+$' ,
        "dsn.rfc-ignorant.org"          => '^127\.0\.0\.\d+$' ,
        "whois.rfc-ignorant.org"        => '^127\.0\.0\.\d+$' ,
        "bogusmx.rfc-ignorant.org"      => '^127\.0\.0\.\d+$' ,
        "blackhole.securitysage.com"    => '^127\.0\.0\.\d+$' ,
        "ex.dnsbl.org"                  => '^127\.0\.0\.\d+$' ,
        "rddn.dnsbl.net.au"             => '^127\.0\.0\.\d+$' ,
        "block.rhs.mailpolice.com"      => '^127\.0\.0\.\d+$' ,
        "dynamic.rhs.mailpolice.com"    => '^127\.0\.0\.\d+$' ,
        "dnsbl.cyberlogic.net"          => '^127\.0\.0\.\d+$' ,
);

our($up) = 'C4';

foreach $arg (@ARGV) {
        $arg =~ s/[\[\]]//g;
        if ($arg =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
                # header
                $rname = gethostbyaddr (pack ($up, (split /\./, $arg)), 2);
                $rname = 'unknown' unless $rname;
                printf "\n\t CLIENT: %s\n", $rname;
                print "\t".("-" x (length($rname) + 10))."\n";

                # RWL checks
                foreach $rwl ( sort keys(%RWLs) ) {
                        $ip = join(".", reverse(split(/\./, $arg))) .".".$rwl;
                        my($mybegin) = time();
                        my($g1,$g2,$g3,$g4,@addrs) = gethostbyname($ip);
                        my($myend) = time();
                        $myresult = join (".", unpack ($up, $addrs[0]));
                        printf "\t%-36s  query time: %2ds", "RWL   ".$rwl, ($myend - $mybegin);
                        ( $myresult =~ /$RWLs{$rwl}/ ) ? printf "  ->  LISTED (%s)", $myresult : printf "  ->  not listed";
                        print "\n";
                };
                # RBL checks
                foreach $rbl ( sort keys(%RBLs) ) {
                        $ip = join(".", reverse(split(/\./, $arg))) .".".$rbl;
                        my($mybegin) = time();
                        my($g1,$g2,$g3,$g4,@addrs) = gethostbyname($ip);
                        my($myend) = time();
                        $myresult = join (".", unpack ($up, $addrs[0]));
                        printf "\t%-36s  query time: %2ds", "RBL   ".$rbl, ($myend - $mybegin);
                        ( $myresult =~ /$RBLs{$rbl}/ ) ? printf "  ->  LISTED (%s)", $myresult : printf "  ->  not listed";
                        print "\n";
                };
        } else {
                $rname = (split /\@/, $arg)[1];
                printf "\n\t DOMAIN: %s\n", $rname;
                print "\t".("-" x (length($rname) + 10))."\n";
        };

        # RHSBL checks
        unless ($rname eq 'unknown') {
                foreach $rhsbl ( sort keys(%RHSBLs) ) {
                        $myquery = $rname.".".$rhsbl;
                        my($mybegin) = time();
                        my($g1,$g2,$g3,$g4,@addrs) = gethostbyname($myquery);
                        my($myend) = time();
                        $myresult = join (".", unpack ($up, $addrs[0]));
                        printf "\t%-36s  query time: %2ds", "RHSBL ".$rhsbl, ($myend - $mybegin);
                        ( $myresult =~ /$RHSBLs{$rhsbl}/ ) ? printf "  ->  LISTED (%s)", $myresult : printf "  ->  not listed";
                        print "\n";
                };
        };
};
print "\n";

