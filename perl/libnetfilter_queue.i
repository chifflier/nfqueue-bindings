%module nfqueue

%{
#include <nfq.h>

#include <nfq_common.h>
%}

%include exception.i




#if defined(SWIGPYTHON)

%include libnetfilter_queue_python.i

#elif defined(SWIGPERL)

%include libnetfilter_queue_perl.i

#endif


%extend queue {

        int open();
        void close();
        int bind();
        int unbind();
        int create_queue(int);
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
        return nfq_set_verdict_mark(self->qh, self->id, d, mark, 0, NULL);
}

int set_verdict_modified(int d, char *new_payload, int new_len) {
        return nfq_set_verdict(self->qh, self->id, d, new_len, new_payload);
}

int set_verdict_mark_modified(int d, int mark, char *new_payload, int new_len) {
        return nfq_set_verdict_mark(self->qh, self->id, d, mark, new_len, new_payload);
}

};

#define NF_DROP   0
#define NF_ACCEPT 1

%include "nfq.h"

