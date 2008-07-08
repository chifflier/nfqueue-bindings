#include <arpa/inet.h>
#include <linux/netfilter.h>
#include <linux/ip.h>

#include <stdio.h>
#include <stdlib.h>

#include "nfq.h"
#include "nfq_common.h"

#include "nfq_version.h"

const char * nfq_bindings_version(void)
{
        return NFQ_BINDINGS_VERSION;
}

int queue_open(struct queue *self)
{
        self->_h = nfq_open();
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
        if (self->_cb == NULL) {
               raise_swig_error("Error: no callback set"); 
               return -1;
        }

        self->_qh = nfq_create_queue(self->_h, 0, &swig_nfq_callback, (void*)self->_cb);
        /*printf("callback argument: %p\n",(void*)self->_cb);*/
        if (self->_qh == NULL) {
               raise_swig_error("error during nfq_create_queue()"); 
               return -1;
        }
        return 0;
}

int queue_fast_open(struct queue *self, int queue_num)
{
	int ret;

        if (self->_cb == NULL) {
               raise_swig_error("Error: no callback set"); 
               return -1;
        }

	ret = queue_open(self);
	if (!ret)
		return -1;

	queue_unbind(self);
	ret = queue_bind(self);
	if (ret < 0) {
		queue_close(self);
		return -1;
	}

	ret = queue_create_queue(self,queue_num);
	if (ret < 0) {
		queue_unbind(self);
		queue_close(self);
		return -1;
	}

	return 0;

}

int queue_set_queue_maxlen(struct queue *self, int maxlen)
{
        int ret;
        ret = nfq_set_queue_maxlen(self->_qh, maxlen);
        if (ret < 0) {
                raise_swig_error("error during nfq_set_queue_maxlen()\n");
        }
        return ret;
}

int queue_try_run(struct queue *self)
{
        int fd;
        int rv;
        char buf[4096];
        struct nfnl_handle *nh;

        printf("setting copy_packet mode\n");
        if (nfq_set_mode(self->_qh, NFQNL_COPY_PACKET, 0xffff) < 0) {
                raise_swig_error("can't set packet_copy mode\n");
                exit(1);
        }

        nh = nfq_nfnlh(self->_h);
        fd = nfnl_fd(nh);

        while ((rv = recv(fd, buf, sizeof(buf), 0)) && rv >= 0) {
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

