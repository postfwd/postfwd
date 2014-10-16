#!/usr/bin/perl -w

## MODULES
#use strict;
use warnings;
use IO::Socket;
use IO::Pipe;
use Getopt::Long 2.25 qw(:config no_ignore_case bundling);
BEGIN {
    eval { require Time::HiRes };
    if ($@) {
        warn "$@";
        warn "Failed to include optional module Time::HiRes.";
    } else {
        Time::HiRes->import( qw(time) );
    };
};


## PARAMETERS
my $syntax = "USAGE: client.pl [ OPTIONS ] <addr>:<port>";
my $sendstr = 'ccert_fingerprint=
size=64063
helo_name=english-breakfast.cloud9.net
reverse_client_name=english-breakfast.cloud9.net
queue_id=
encryption_cipher=
encryption_protocol=
etrn_domain=
ccert_subject=
request=smtpd_access_policy
protocol_state=RCPT
recipient=someone@domain.local
instance=6748.46adf3f8.62156.0
protocol_name=ESMTP
encryption_keysize=0
recipient_count=0
ccert_issuer=
sender=owner-postfix-users@postfix.org
client_name=english-breakfast.cloud9.net
client_address=168.100.1.7

';
my $delay = 0.5;
our $pipe = new IO::Pipe;
use vars qw( %options %kinder $kind $wait );

## COMMAND LINE
GetOptions( \%options,
  'verbose|v+',
  'quiet|q+',
  'process|p=i',
  'count|c=i',
  'timeout|t=i',
  'file|f=s',
) or die "$syntax\n";
die "$syntax\n" unless $ARGV[0];
map { $options{$_} ||= 1 } qw(count process);
$options{verbose} ||= 0;
$options{timeout} ||= 3;
if (defined $options{file}) {
  (-f $options{file}) || die "can not find file '".$options{file}."'\n";
  open (REQUEST, "<".$options{file}) || die "can not open file '".$options{file}."'\n";
  $sendstr = join "", <REQUEST>;
  close (REQUEST);
};

## FORK
$| = 1;
my $starttime = time();
FORK: for (my $i=0;$i<$options{process};$i++) {
	$kind = fork();
	last FORK unless $kind;
	$kinder{$kind} = 1;
};

## WHO AM I?
($kind) ? parent_process() : child_process() ;
die "should never see me\n";
exit(1);

## PARENT CODE
sub parent_process {
  $pipe->reader();
  use POSIX ":sys_wait_h";
  undef my @status;
  # wait until children have finished
  print ("parent process waiting for ".(scalar keys %kinder)." pids ".(join ' ', (keys %kinder))."\n") unless $options{quiet};
  PARENT: do {
    # check pipe for finished children
    push @status, <$pipe>;
    # check children
    CHILD: foreach (keys %kinder) {
	$wait = waitpid($_,&WNOHANG);
	last CHILD unless ($wait == -1);
	delete $kinder{$_};
    };
    # sleep a while to reduce cpu usage
    select(undef, undef, undef, $delay);
    print ("parent process waiting for ".(scalar keys %kinder)." pids ".(join ' ', (keys %kinder))."\n") if ($options{verbose} > 1);
  } until (($wait == -1) or (($#status + 1) >= $options{process}));
  printf ("parent process finished after %.2f seconds.\n", (time() - $starttime)) unless $options{quiet};
  # display results
  my $parent_requests = my $parent_errors = my $parent_valid = my $parent_invalid = my $parent_time = 0;
  foreach (@status) {
	my($child_requests,$child_errors,$child_valid,$child_invalid,$child_time) = split ';', $_;
	$parent_requests += $child_requests;
	$parent_errors += $child_errors;
	$parent_valid += $child_valid;
	$parent_invalid += $child_invalid;
	$parent_time = $child_time if ($child_time > $parent_time);
  };
  $parent_time = $parent_time - $starttime;
  my $parent_rps = ($parent_time) ? ($parent_requests / $parent_time) : 0;
  printf "%d requests, %d errors, %d valid, %d invalid, %.2fs total time, %.2f requests per second\n",
	$parent_requests,$parent_errors,$parent_valid,$parent_invalid,$parent_time,$parent_rps;
  exit (0);
};

## CHILD CODE
sub child_process {
  $pipe->writer();
  my $ok = my $nok = 0;
  undef my $getstr;
  # open socket
  my($addr,$port) = split ':', $ARGV[0];
  if ( ($addr and $port) and my $socket = new IO::Socket::INET (
    PeerAddr => $addr,
    PeerPort => $port,
    Proto    => 'tcp',
    Timeout  => $options{timeout},
    Type     => SOCK_STREAM ) ) {
    # submit requests
    for (my $i=0; $i<$options{count}; $i++) {
           printf ("CHILD-$$: asking service $addr:$port\n") if $options{verbose};
           print $socket "$sendstr";
           $getstr = <$socket>; <$socket>;
           chomp($getstr);
           printf ("CHILD-$$: answer from $addr:$port -> '$getstr'\n") if $options{verbose};
           $getstr =~ s/^(action=)//;
           # check answer
           if ($1 and $getstr) {
                   $ok++;
                   printf ("CHILD-$$: OK: answer from $addr:$port -> '$getstr'\n") unless ( $options{quiet} or (($options{count} * $options{process}) > 50) );
           } else {
                   $nok++;
                   warn ("CHILD-$$: FAIL: invalid answer from $addr:$port -> '$getstr'\n");
           };
    };
  } else {
    warn ("CHILD-$$: can not open socket to $addr:$port\n");
  };
  # create summary
  my $summary = $options{count}.';'.($options{count} - ($ok + $nok)).';'.$ok.';'.$nok.';'.time()."\n";
  print ("CHILD-$$: child summary: $summary") if ($options{verbose} > 1);
  # send summary to parent
  print $pipe "$summary";
  exit (0);
};

