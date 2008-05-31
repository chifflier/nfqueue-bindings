#!/usr/bin/perl -w
#
# see http://search.cpan.org/~atrak/NetPacket-0.04/

use strict;

BEGIN {
	push @INC,"perl";
	push @INC,"build/perl";
	push @INC,"NetPacket-0.04";
};

use nfqueue;

use NetPacket::IP qw(IP_PROTO_TCP);
use NetPacket::TCP;

my $debug = 1;
my $q;

sub cleanup()
{
	print "unbind\n";
	$q->unbind();
	print "close\n";
	$q->close();
}

my @http_checks = (
	"^GET ",
	"^User-Agent",
);

sub _check_http
{
	my $data = shift;

	foreach my $check (@http_checks) {
		return 0 unless ($data =~ /$check/moi);
	}

	return 1;
}

sub cb
{
	my ($dummy,$payload) = @_;

	if ($payload) {
		print "\n";

		my $ip_obj = NetPacket::IP->decode($payload->get_data());
		print "Id: " . $payload->swig_id_get() . "\n";

		if($ip_obj->{proto} == IP_PROTO_TCP) {
			# decode the TCP header
			my $tcp_obj = NetPacket::TCP->decode($ip_obj->{data});

			if ($tcp_obj->{flags} & NetPacket::TCP::SYN) {
				print("$ip_obj->{src_ip} => $ip_obj->{dest_ip} $ip_obj->{proto}\n");
				print "TCP src_port: $tcp_obj->{src_port}\n";
				print "TCP dst_port: $tcp_obj->{dest_port}\n";
				print "TCP flags   : $tcp_obj->{flags}\n";
			}
			elsif ($tcp_obj->{flags} & NetPacket::TCP::PSH) {
				print "TCP data:\n";
				print "*" x 50 . "\n";
				print $tcp_obj->{data};
				print "*" x 50 . "\n";
				if ($tcp_obj->{dest_port} == 80) {
					_check_http($tcp_obj->{data}) or return $payload->set_verdict($nfqueue::NF_DROP);
				}
			}
		}

		print "\n";
		$payload->set_verdict($nfqueue::NF_ACCEPT);
	}
}


$q = new nfqueue::queue();

print "open\n";
$q->open();
print "bind\n";
$q->bind();

$SIG{INT} = "cleanup";

#print "set callback, wrong argument type (should fail)\n";
#$q->set_callback("blah");

print "setting callback\n";
$q->set_callback(\&cb);

print "creating queue\n";
$q->create_queue(0);

print "trying to run\n";
$q->try_run();


