#include <arpa/inet.h>
#include <linux/netfilter.h>
#include <linux/ip.h>

#include <stdio.h>
#include <stdlib.h>

#include "exception.h"

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

int queue_bind(struct queue *self, int af_family)
{
        if (nfq_bind_pf(self->_h, af_family)) {
                throw_exception("error during nfq_bind_pf()");
                return -1;
        }
        return 0;
}

int queue_unbind(struct queue *self, int af_family)
{
        if (nfq_unbind_pf(self->_h, af_family)) {
                throw_exception("error during nfq_unbind_pf()");
                return -1;
        }
        return 0;
}

int queue_create_queue(struct queue *self, int queue_num)
{
        if (self->_cb == NULL) {
               throw_exception("Error: no callback set");
               return -1;
        }

        self->_qh = nfq_create_queue(self->_h, queue_num, &swig_nfq_callback, (void*)self->_cb);
        /*printf("callback argument: %p\n",(void*)self->_cb);*/
        if (self->_qh == NULL) {
               throw_exception("error during nfq_create_queue()");
               return -1;
        }
        self->_mode_set = 0;
        return 0;
}

int queue_fast_open(struct queue *self, int queue_num, int af_family)
{
        int ret;

        if (self->_cb == NULL) {
               throw_exception("Error: no callback set");
               return -1;
        }

        ret = queue_open(self);
        if (!ret)
                return -1;

        queue_unbind(self, af_family);
        ret = queue_bind(self, af_family);
        if (ret < 0) {
                queue_close(self);
                return -1;
        }

        ret = queue_create_queue(self,queue_num);
        if (ret < 0) {
                queue_unbind(self, af_family);
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
                throw_exception("error during nfq_set_queue_maxlen()\n");
        }
        return ret;
}

int queue_get_fd(struct queue *self)
{
        if (self->_h == NULL) {
                throw_exception("queue is not open");
                return -1;
        }
        return nfq_fd(self->_h);
}

int queue_set_mode(struct queue *self, int mode)
{
        if (self->_qh == NULL) {
                throw_exception("queue is not created");
                return -1;
        }
        if (nfq_set_mode(self->_qh, mode, 0xffff) < 0) {
                throw_exception("can't set queue mode");
                return -1;
        }
        self->_mode_set = 1;
        return 0;
}

int _process_loop(struct queue *self, int fd, int flags, int max_count)
{
        int rv;
        char buf[65535];
        int count;

        count = 0;

        while ((rv = recv(fd, buf, sizeof(buf), flags)) >= 0) {
                nfq_handle_packet(self->_h, buf, rv);
                count++;
                if (max_count > 0 && count >= max_count) {
                        break;
                }
        }
        return count;
}

int queue_try_run(struct queue *self)
{
        int fd;

        if ((fd = queue_get_fd(self)) < 0) {
                /* exception has been thrown by queue_get_fd */
                return -1;
        } else if ((!self->_mode_set)) {
	        if (queue_set_mode(self, NFQNL_COPY_PACKET) < 0) {
                        /* exception has been thrown by queue_set_mode */
                        return -1;
	        }
        }

        return _process_loop(self, fd, 0, -1);
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

