#ifndef __NFQ_H__
#define __NFQ_H__

#include <libnetfilter_queue/libnetfilter_queue.h>

struct queue {
        int dummy;

        struct nfq_handle *_h;
        struct nfq_q_handle *_qh;
        void *_cb;
};

struct payload {
        char *data;
        unsigned int len;
        int id;
        struct nfq_q_handle *qh;
        struct nfq_data *nfad;
};

#endif /* __NFQ_H__ */
