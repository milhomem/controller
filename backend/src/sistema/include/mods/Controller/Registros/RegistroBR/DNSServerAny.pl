#!/usr/bin/perl

use Net::DNS::Nameserver;
use strict;
use warnings;

sub reply_handler {
	my ($qname, $qclass, $qtype, $peerhost,$query,$conn) = @_;
	my ($rcode, @ans, @auth, @add);
	
	my ($ttl, $rdata) = (3600, "127.0.0.1");
	push @ans, Net::DNS::RR->new("$qname $ttl $qclass $qtype $rdata") if $qtype ne 'AAAA';
	$rcode = "NOERROR";

	#mark the answer as authoritive (by setting the 'aa' flag
	return ($rcode, \@ans, \@auth, \@add, { aa => 1 });
}

my $ns = Net::DNS::Nameserver->new(
#    LocalAddr    => "127.0.0.1",
    LocalPort    => 53,
    ReplyHandler => \&reply_handler,
#    Verbose      => 1,
) || die "couldn't create nameserver object\n";

$ns->main_loop;

=pod
Startup sample
#!/bin/sh
echo -n ' DNSServerAny '

case "$1" in
start)
        perl /usr/local/bin/DNSServerAny.pl &
        echo "start ...[OK]"
        ;;
stop)
        kill -9 `ps aux |grep DNSServerAny.pl |grep -v grep |awk '{print$2}'`
        echo "stop ...[OK]"
        ;;
*)
        echo "Usage: `basename $0` {start|stop}" >&2
        exit 64
        ;;
esac

exit 0
=cut