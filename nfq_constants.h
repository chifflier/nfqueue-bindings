/*
 * Don't include this file in C headers.  It's only used to export some
 * external library header constants to our modules, through %include in the
 * swig interface file.
 *
 */

#ifndef SWIG
#error "Only include in swig interface"
#endif

#include <linux/netfilter.h>
#include <libnetfilter_queue/libnetfilter_queue.h>

const int NF_DROP = NF_DROP;
const int NF_ACCEPT = NF_ACCEPT;
const int NF_STOLEN = NF_STOLEN;
const int NF_QUEUE = NF_QUEUE;
const int NF_REPEAT = NF_REPEAT;
const int NF_STOP = NF_STOP;
const int NF_MAX_VERDICT = NF_STOP;

const int NFQNL_COPY_NONE = NFQNL_COPY_NONE;
const int NFQNL_COPY_META = NFQNL_COPY_META;
const int NFQNL_COPY_PACKET = NFQNL_COPY_PACKET;

