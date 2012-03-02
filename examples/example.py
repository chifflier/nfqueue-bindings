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
from dpkt import ip

count = 0

def cb(payload):
	global count

	print "python callback called !"
	count += 1

	data = payload.get_data()
	pkt = ip.IP(data)
	if pkt.p == ip.IP_PROTO_TCP:
		print "  len %d proto %s src: %s:%s    dst %s:%s " % (payload.get_length(),pkt.p,inet_ntoa(pkt.src),pkt.tcp.sport,inet_ntoa(pkt.dst),pkt.tcp.dport)
	else:
		print "  len %d proto %s src: %s    dst %s " % (payload.get_length(),pkt.p,inet_ntoa(pkt.src),inet_ntoa(pkt.dst))

	payload.set_verdict(nfqueue.NF_ACCEPT)

	sys.stdout.flush()
	return 1

q = nfqueue.queue()

print "setting callback"
q.set_callback(cb)

print "open"
q.fast_open(0, AF_INET)

q.set_queue_maxlen(50000)

print "trying to run"
try:
	q.try_run()
except KeyboardInterrupt, e:
	print "interrupted"

print "%d packets handled" % count

print "unbind"
q.unbind(AF_INET)

print "close"
q.close()

