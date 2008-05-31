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
};

#define NF_DROP   0
#define NF_ACCEPT 1

%include "nfq.h"

