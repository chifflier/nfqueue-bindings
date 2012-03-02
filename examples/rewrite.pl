#!/usr/bin/perl
#
# see http://search.cpan.org/~atrak/NetPacket-0.04/

#use strict;

BEGIN {
	push @INC,"perl";
	push @INC,"build/perl";
	push @INC,"NetPacket-0.04";
};

use nfqueue;

use NetPacket::IP qw(IP_PROTO_TCP);
use NetPacket::TCP;
use Socket qw(AF_INET AF_INET6);

my $q;

sub cleanup()
{
	print "unbind\n";
	$q->unbind(AF_INET);
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
		print("$ip_obj->{src_ip} => $ip_obj->{dest_ip} $ip_obj->{proto}\n");
		print "Id: " . $payload->swig_id_get() . "\n";

		if($ip_obj->{proto} == IP_PROTO_TCP) {
			# decode the TCP header
			my $tcp_obj = NetPacket::TCP->decode($ip_obj->{data});

			print "TCP src_port: $tcp_obj->{src_port}\n";
			print "TCP dst_port: $tcp_obj->{dest_port}\n";
			print "TCP flags   : $tcp_obj->{flags}\n";
			print "TCP data    : $tcp_obj->{data}\n";

			if ($tcp_obj->{flags} & NetPacket::TCP::PSH &&
					length($tcp_obj->{data})) {
				print "data is defined\n";
				#$tcp_obj->{data} = 'gruik';
				$tcp_obj->{data} =~ s/love/hate/m;
				print "**********\n";
				print $tcp_obj->{data};
				print "**********\n";
			}

                        # try modifying the packet
                        #$ip_obj->{src_ip} = "1.2.3.4";
                        #$tcp_obj->{src_port} = 42;
			#$ip_obj->{dest_ip} = "213.186.33.19";
			$tcp_obj->{checksum} = 0;
			$ip_obj->{checksum} = 0;
                        $ip_obj->{data} = $tcp_obj->encode($ip_obj);
                        my $modified_payload = $ip_obj->encode();
                        my $ip2 = NetPacket::IP->decode($modified_payload);
                        print("$ip2->{src_ip} => $ip2->{dest_ip} $ip2->{proto}\n");
			my $tcp2 = NetPacket::TCP->decode($ip2->{data});

			print "TCP src_port: $tcp2->{src_port}\n";
			print "TCP dst_port: $tcp2->{dest_port}\n";

                        print "data length: ", length($modified_payload), "\n";

                        my $ret = $payload->set_verdict_modified($nfqueue::NF_ACCEPT,$modified_payload,length($modified_payload));
			print "ret: $ret\n";
			return;
		}

		$payload->set_verdict($nfqueue::NF_ACCEPT);
		return;
	}
	$payload->set_verdict($nfqueue::NF_ACCEPT);
}


$q = new nfqueue::queue();

$SIG{INT} = "cleanup";

print "setting callback\n";
$q->set_callback(\&cb);

print "open\n";
$q->fast_open(0, AF_INET);

print "trying to run\n";
$q->try_run();


