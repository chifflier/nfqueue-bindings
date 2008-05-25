#!/usr/bin/perl -w
#
# see http://search.cpan.org/~atrak/NetPacket-0.04/

use strict;

BEGIN {
	push @INC,"perl";
	push @INC,"NetPacket-0.04";
};

use nfqueue;

use NetPacket::IP qw(IP_PROTO_TCP);
use NetPacket::TCP;

my $q;

sub cleanup()
{
	print "unbind\n";
	$q->unbind();
	print "close\n";
	$q->close();
}

sub cb()
{
	my ($dummy,$payload) = @_;
	print "Perl callback called!\n";
	print "dummy is $dummy\n" if $dummy;
	if ($payload) {
		print "len: " . $payload->get_length() . "\n";

		my $ip_obj = NetPacket::IP->decode($payload->get_data());
		print $ip_obj, "\n";
		print("$ip_obj->{src_ip}:$ip_obj->{dest_ip} $ip_obj->{proto}\n");

		if($ip_obj->{proto} == IP_PROTO_TCP) {
			# decode the TCP header
			my $tcp_obj = NetPacket::TCP->decode($ip_obj->{data});

			print "TCP src_port: $tcp_obj->{src_port}\n";
			print "TCP dst_port: $tcp_obj->{dest_port}\n";
		}
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


