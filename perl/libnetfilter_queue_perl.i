
// Grab a Perl function object as a Perl object.
%typemap(in) void *perl_cb {
  SV *obj = $input;
  if (SvROK(obj)) {
        obj = SvRV($input);
  }
  if (SvTYPE(obj) != SVt_PVCV) {
          SWIG_Error(SWIG_TypeError, "Parameter is not a function"); 
          return;
  }
  $1 = obj;
}

%{
#include <arpa/inet.h>
#include <linux/netfilter.h>
#include <linux/ip.h>

#include "nfq_utils.h"

int  swig_nfq_callback(struct nfq_q_handle *qh, struct nfgenmsg *nfmsg,
                       struct nfq_data *nfad, void *data)
{
        int id = 0;
        struct nfqnl_msg_packet_hdr *ph;
        char *payload_data;
        int payload_len;

        if (data == NULL) {
                fprintf(stderr,"No callback set !\n");
                return -1;
        }

        ph = nfq_get_msg_packet_hdr(nfad);
        if (ph){
                id = ntohl(ph->packet_id);
        }

        if ((payload_len = nfq_get_payload(nfad, &payload_data)) < 0) {
                fprintf(stderr, "Couldn't get payload\n");
                return -1;
        }

        /*printf("callback called\n");
        printf("callback argument: %p\n",data);*/

        {
                SV *func = (SV*)data;
                struct payload *p;
                SV * payload_obj;

                dSP ;
                ENTER ;
                SAVETMPS ;

                PUSHMARK(SP) ;

                XPUSHs(sv_2mortal(newSViv(42)));
                p = malloc(sizeof(struct payload));
                p->data = payload_data;
                p->len = payload_len;
                p->id = id;
                p->qh = qh;
                p->nfad = nfad;
                payload_obj = sv_newmortal();
                SWIG_MakePtr(payload_obj, (void*) p, SWIGTYPE_p_payload, 0);
                XPUSHs(payload_obj);

                PUTBACK;

                call_sv(func, G_DISCARD);
                free(p);

                FREETMPS ;
                LEAVE ;
        }

        return nfq_set_verdict(qh, id, NF_ACCEPT, 0, NULL);
}

%}

%extend queue {

int set_callback(void *perl_cb)
{
        self->_cb = (void*)perl_cb;
        return 0;
}

};

%typemap (out) const char* get_data {
        $result = sv_2mortal(newSVpvn($1,arg1->len)); // blah
        argvi++;
}

%extend payload {
const char* get_data(void) {
        return self->data;
}
};

