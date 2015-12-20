#!/usr/bin/python

# need root privileges

import struct
import sys
import time
import asyncore

from socket import AF_INET, AF_INET6, inet_ntoa

sys.path.append('python')
sys.path.append('build/python')
import nfqueue

sys.path.append('dpkt-1.6')
from dpkt import ip

def cb(payload):
  print "python callback called !"

  print "payload len ", payload.get_length()
  data = payload.get_data()
  pkt = ip.IP(data)
  print "proto:", pkt.p
  print "source: %s" % inet_ntoa(pkt.src)
  print "dest: %s" % inet_ntoa(pkt.dst)
  if pkt.p == ip.IP_PROTO_TCP:
    print "  sport: %s" % pkt.tcp.sport
    print "  dport: %s" % pkt.tcp.dport
    payload.set_verdict(nfqueue.NF_DROP)

  sys.stdout.flush()
  return 1

class AsyncNfQueue(asyncore.file_dispatcher):
  """An asyncore dispatcher of nfqueue events.

  """

  def __init__(self, cb, nqueue=0, family=AF_INET, maxlen=5000, map=None):
    self._q = nfqueue.queue()
    self._q.set_callback(cb)
    self._q.fast_open(nqueue, family)
    self._q.set_queue_maxlen(maxlen)
    self.fd = self._q.get_fd()
    asyncore.file_dispatcher.__init__(self, self.fd, map)
    self._q.set_mode(nfqueue.NFQNL_COPY_PACKET)

  def handle_read(self):
    print "Processing at most 5 events"
    self._q.process_pending(5)

  # We don't need to check for the socket to be ready for writing
  def writable(self):
    return False

async_queue = AsyncNfQueue(cb)
asyncore.loop()

