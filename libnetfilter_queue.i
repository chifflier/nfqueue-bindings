%module nfqueue

%{
#include <nfq.h>

#include <nfq_common.h>
%}

%include exception.i




#if defined(SWIGPYTHON)

%include python/libnetfilter_queue_python.i

#elif defined(SWIGPERL)

%include perl/libnetfilter_queue_perl.i

#endif


%extend queue {

        int open();
        void close();
        int bind(int);
        int unbind(int);
        int create_queue(int);
        int fast_open(int, int);
        int set_queue_maxlen(int);
        int try_run();
};

%extend payload {
        int get_nfmark();
        int get_indev();
        int get_outdev();

unsigned int get_length(void) {
        return self->len;
}

int set_verdict(int d) {
        return nfq_set_verdict(self->qh, self->id, d, 0, NULL);
}

int set_verdict_mark(int d, int mark) {
        return nfq_set_verdict_mark(self->qh, self->id, d, htonl(mark), 0, NULL);
}

int set_verdict_modified(int d, char *new_payload, int new_len) {
        return nfq_set_verdict(self->qh, self->id, d, new_len, new_payload);
}

int set_verdict_mark_modified(int d, int mark, char *new_payload, int new_len) {
        return nfq_set_verdict_mark(self->qh, self->id, d, htonl(mark), new_len, new_payload);
}

};

/* taken from /usr/include/linux/netfilter.h */
#define NF_DROP   0
#define NF_ACCEPT 1
#define NF_STOLEN 2
#define NF_QUEUE 3
#define NF_REPEAT 4
#define NF_STOP 5
#define NF_MAX_VERDICT NF_STOP

%include "nfq.h"

const char * nfq_bindings_version(void);

