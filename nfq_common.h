#ifndef __NFQ_COMMON__
#define __NFQ_COMMON__

extern void raise_swig_error(const char *errstr);
extern int  swig_nfq_callback(struct nfq_q_handle *qh, struct nfgenmsg *nfmsg,
                       struct nfq_data *nfad, void *data);

int queue_open(struct queue *self);

void queue_close(struct queue *self);

int queue_bind(struct queue *self);

int queue_unbind(struct queue *self);

int queue_set_queue_maxlen(struct queue *self, int maxlen);

int queue_create_queue(struct queue *self, int queue_num);

int queue_try_run(struct queue *self);

int payload_get_nfmark(struct payload *self);

int payload_get_indev(struct payload *self);

int payload_get_outdev(struct payload *self);

#endif /* __NFQ_COMMON__ */
