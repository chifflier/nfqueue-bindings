#include <arpa/inet.h>
#include <linux/netfilter.h>
#include <linux/ip.h>

#include <stdio.h>
#include <stdlib.h>

#include "nfq.h"
#include "nfq_common.h"

int queue_open(struct queue *self)
{
        self->_h = nfq_open();
        self->_cb = NULL;
        self->_qh = NULL;
        return (self->_h != NULL);
}

void queue_close(struct queue *self)
{
        nfq_close(self->_h);
        self->_qh = NULL;
        self->_h = NULL;
        self->_cb = NULL;
}

int queue_bind(struct queue *self)
{
        if (nfq_bind_pf(self->_h, AF_INET)) {
                raise_swig_error("error during nfq_bind_pf()"); 
                return -1;
        }
        return 0;
}

int queue_unbind(struct queue *self)
{
        if (nfq_unbind_pf(self->_h, AF_INET)) {
                raise_swig_error("error during nfq_unbind_pf()"); 
                return -1;
        }
        return 0;
}

int queue_create_queue(struct queue *self, int queue_num)
{
        self->_qh = nfq_create_queue(self->_h, 0, &swig_nfq_callback, (void*)self->_cb);
        /*printf("callback argument: %p\n",(void*)self->_cb);*/
        if (self->_qh == NULL) {
               raise_swig_error("error during nfq_create_queue()"); 
               return -1;
        }
        return 0;
}

int queue_try_run(struct queue *self)
{
        int fd;
        int rv;
        char buf[4096];
        struct nfnl_handle *nh;
        u_int32_t qlen = 1024;

        printf("setting copy_packet mode\n");
        if (nfq_set_mode(self->_qh, NFQNL_COPY_PACKET, 0xffff) < 0) {
                raise_swig_error("can't set packet_copy mode\n");
                exit(1);
        }

        if (nfq_set_queue_maxlen(self->_qh, qlen) < 0)
        {
                raise_swig_error("error during nfq_set_queue_maxlen()\n");
                // exit(1);
        }


        nh = nfq_nfnlh(self->_h);
        fd = nfnl_fd(nh);

        while ((rv = recv(fd, buf, sizeof(buf), 0)) && rv >= 0) {
                printf("pkt received\n");
                nfq_handle_packet(self->_h, buf, rv);
        }

        printf("exiting try_run\n");
        return 0;
}

int payload_get_nfmark(struct payload *self)
{
        return nfq_get_nfmark(self->nfad);
}

int payload_get_indev(struct payload *self)
{
        return nfq_get_indev(self->nfad);
}

int payload_get_outdev(struct payload *self)
{
        return nfq_get_outdev(self->nfad);
}

