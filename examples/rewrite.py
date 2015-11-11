#!/usr/bin/python

# need root privileges

import struct
import sys
import time

from socket import AF_INET, AF_INET6, inet_ntoa

sys.path.append('python')
sys.path.append('build/python')
import nfqueue

sys.path.append('dpkt-1.6')
from dpkt import ip, tcp, hexdump

def cb(payload):
	print "payload len ", payload.get_length()
	data = payload.get_data()
	pkt = ip.IP(data)
	print "proto:", pkt.p
	print "source: %s" % inet_ntoa(pkt.src)
	print "dest: %s" % inet_ntoa(pkt.dst)
	if pkt.p == ip.IP_PROTO_TCP:
	 	print "  sport: %s" % pkt.tcp.sport
	 	print "  dport: %s" % pkt.tcp.dport
	 	print "  flags: %s" % pkt.tcp.flags
                if pkt.tcp.flags & tcp.TH_PUSH:
			pkt2 = pkt
                        print "PUSH *****"
                        print pkt2.tcp.data
			old_len = len(pkt2.tcp.data)
                        #pkt2.tcp.data = "GET /\r\n"
                        pkt2.tcp.data = str(pkt2.tcp.data).replace('love','hate')
                        print pkt2.tcp.data
			pkt2.len = pkt2.len - old_len + len(pkt2.tcp.data)
                        pkt2.tcp.sum = 0
                        pkt2.sum = 0

                        ret = payload.set_verdict_modified(nfqueue.NF_ACCEPT,str(pkt2),len(pkt2))
                        print "ret = ",ret

                        return 0
        payload.set_verdict(nfqueue.NF_ACCEPT)

	sys.stdout.flush()
	return 1

q = nfqueue.queue()

print "setting callback"
q.set_callback(cb)

print "open"
q.fast_open(0, AF_INET)

print "trying to run"
try:
	q.try_run()
except KeyboardInterrupt, e:
	print "interrupted"


print "unbind"
q.unbind(AF_INET)

print "close"
q.close()

