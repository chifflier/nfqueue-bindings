# nfqueue-bindings

[![Build Status](https://travis-ci.org/chifflier/nfqueue-bindings.svg?branch=master)](https://travis-ci.org/chifflier/nfqueue-bindings)

## Overview

nfqueue-bindings was written to provide an interface in high-level
languages such as Perl or Python to libnetfilter_queue.
The goal is to provide a library to gain access to packets queued by
the kernel packet filter.

It is important to note that these bindings will not follow blindly
libnetfilter_queue API. For ex., some higher-level wrappers will be provided
for the open/bind/create mechanism (using one function call instead of
three).

Since libraries to decode ip packets are already available, the bindings
will use them.

Remember that an application connection to libnetfilter_queue must run as
root to be able to create the queue. Some extra steps may be required
to drop privileges after if you need more security.

## iptables

You must add rules in netfilter to send packets to the userspace queue.
The number of the queue (--queue-num option in netfilter) must match the
number provided to create_queue().

Example of iptables rules::

    iptables -A OUTPUT --destination 1.2.3.4 -j NFQUEUE

Of course, you should be more restrictive, depending on your needs.

## Other languages

Bindings for the Go languages are available in the
[nfqueue-go](https://github.com/chifflier/nfqueue-go) project. They are not
generated using Swig, so they are not part of this project.
