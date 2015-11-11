#!/usr/bin/python

# need root privileges

import struct
import sys
import time

from PyQt4.QtGui import QApplication, QMessageBox, QPixmap

from socket import AF_INET, AF_INET6, inet_ntoa

sys.path.append('python')
sys.path.append('build/python')
import nfqueue

sys.path.append('dpkt-1.6')
from dpkt import ip, tcp

decisions = dict()

def cb(payload):
	data = payload.get_data()
	pkt = ip.IP(data)
	print ""
	print "proto:", pkt.p
	print "source: %s" % inet_ntoa(pkt.src)
	print "dest: %s" % inet_ntoa(pkt.dst)
	text_dst = None
	if pkt.p == ip.IP_PROTO_TCP:
	 	print "  sport: %s" % pkt.tcp.sport
	 	print "  dport: %s" % pkt.tcp.dport
		text = "%s:%s => %s:%s" % (inet_ntoa(pkt.src),pkt.tcp.sport, inet_ntoa(pkt.dst), pkt.tcp.dport)
		text_dst = "%s:%s" % (inet_ntoa(pkt.dst), pkt.tcp.dport)
		if (not (pkt.tcp.flags & tcp.TH_SYN)):
			return payload.set_verdict(nfqueue.NF_ACCEPT)
	else:
		text = "%s => %s" % (inet_ntoa(pkt.src), inet_ntoa(pkt.dst))
	
	if text_dst and decisions.has_key(text_dst):
		print "shortcut: %s (%d)" % (text_dst,decisions[text_dst])
		return payload.set_verdict(decisions[text_dst])

	reply = QMessageBox.question(None,'accept packet ?',text,QMessageBox.Yes, QMessageBox.No)
	if reply == QMessageBox.Yes:
		payload.set_verdict(nfqueue.NF_ACCEPT)
		decisions[text_dst] = nfqueue.NF_ACCEPT
	else:
		payload.set_verdict(nfqueue.NF_DROP)
		decisions[text_dst] = nfqueue.NF_DROP

	return 0


app = QApplication(sys.argv)

q = nfqueue.queue()

q.set_callback(cb)

ret = q.fast_open(0, AF_INET)
if ret != 0:
	print "could not open queue %d" % 0
	sys.exit(-1)

try:
	q.try_run()
except KeyboardInterrupt, e:
	print "interrupted"


q.unbind(AF_INET)
q.close()

