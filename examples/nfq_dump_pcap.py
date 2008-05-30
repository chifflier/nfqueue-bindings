#!/usr/bin/python

# need root privileges

import struct
import sys
import time

from socket import AF_INET, AF_INET6, inet_ntoa

sys.path.append('python')
sys.path.append('build/python')
import nfqueue

outputfile = None
outputfilename = "dump.pcap"

from scapy import Packet, PcapWriter, hexdump

writer = None

def cb(i,payload):
    data = payload.get_data()

    # Add padding before packet
    # src mac + dst mac + 0x0800 (type: IP)
    pad = "\0" * 12 + "\x08\0" + data

    pkt = Packet(_pkt=pad)
    writer.write(pkt)

    return 1

q = nfqueue.queue()

q.open()

q.unbind()
if q.bind() != 0:
    q.close()
    raise RuntimeError("Could not bind to nfqueue")

writer = PcapWriter(outputfilename)

q.set_callback(cb)

q.create_queue(0)

try:
    q.try_run()
except KeyboardInterrupt, e:
    pass


q.unbind()
q.close()

