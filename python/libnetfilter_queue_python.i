
// Grab a Python function object as a Python object.
%typemap(in) PyObject *pyfunc {
  if (!PyCallable_Check($input)) {
      PyErr_SetString(PyExc_TypeError, "Need a callable object!");
      return NULL;
  }
  $1 = $input;
}

%{
#include <arpa/inet.h>
#include <linux/netfilter.h>
#include <linux/ip.h>

#include <nfq_utils.h>

int  swig_nfq_callback(struct nfq_q_handle *qh, struct nfgenmsg *nfmsg,
                       struct nfq_data *nfad, void *data)
{
        int id = 0;
        struct nfqnl_msg_packet_hdr *ph;
        u_int32_t mark,ifi;
        int ret;
        char *payload_data;
        int payload_len;
        struct timeval tv1, tv2, diff;

        ph = nfq_get_msg_packet_hdr(nfad);
        if (ph){
                id = ntohl(ph->packet_id);
                printf("hw_protocol=0x%04x hook=%u id=%u ",
                                ntohs(ph->hw_protocol), ph->hook, id);
        }

        mark = nfq_get_nfmark(nfad);
        if (mark)
                printf("mark=%u ", mark);

        ifi = nfq_get_indev(nfad);
        if (ifi)
                printf("indev=%u ", ifi);

        ifi = nfq_get_outdev(nfad);
        if (ifi)
                printf("outdev=%u ", ifi);

        ret = nfq_get_payload(nfad, &payload_data);
        if (ret >= 0)
                printf("payload_len=%d ", ret);

        fputc('\n', stdout);

        {
                struct iphdr * hdr;
                payload_len = ret;
                char *saddr, *daddr;

                hdr = (struct iphdr *)payload_data;

                printf("payload_version=%d ", hdr->version);

                printf("protocol=%d ", hdr->protocol);

                saddr = (char*)&hdr->saddr;
                if (saddr) {
                        printf("saddr=%hhu.%hhu.%hhu.%hhu ",
                        saddr[0],
                        saddr[1],
                        saddr[2],
                        saddr[3]
                        );
                }
                daddr = (char*)&hdr->daddr;
                if (daddr) {
                        printf("daddr=%hhu.%hhu.%hhu.%hhu ",
                        daddr[0],
                        daddr[1],
                        daddr[2],
                        daddr[3]
                        );
                }



                fputc('\n', stdout);
        }

        gettimeofday(&tv1, NULL);

        /*printf("callback called\n");
        printf("callback argument: %p\n",data);*/

        {
                PyObject *func, *arglist, *payload_obj;
                PyObject *result;
                struct payload *p;

                SWIG_PYTHON_THREAD_BEGIN_ALLOW;
                func = (PyObject *) data;
                p = malloc(sizeof(struct payload));
                p->data = payload_data;
                p->len = payload_len;
                p->id = id;
                p->qh = qh;
                payload_obj = SWIG_NewPointerObj((void*) p, SWIGTYPE_p_payload, 1);
                arglist = Py_BuildValue("(i,O)",42,payload_obj);
                /*printf("will call python object\n");*/
                result = PyEval_CallObject(func,arglist);
                /*printf("result: %p\n", result);*/
                Py_DECREF(arglist);
                if (result) {
                        Py_DECREF(result);
                }
                result = PyErr_Occurred();
                if (result) {
                        printf("callback failure !\n");
                        PyErr_Print();
                }
                SWIG_PYTHON_THREAD_END_ALLOW;
        }

        gettimeofday(&tv2, NULL);

        timeval_subtract(&diff, &tv2, &tv1);
        printf("python callback call: %d sec %d usec\n",
                (int)diff.tv_sec,
                (int)diff.tv_usec);

        return nfq_set_verdict(qh, id, NF_ACCEPT, 0, NULL);
}

void raise_swig_error(const char *errstr)
{
        fprintf(stderr,"ERROR %s\n",errstr);
        SWIG_Error(SWIG_RuntimeError, errstr); 
}
%}

%extend queue {

int set_callback(PyObject *pyfunc)
{
        self->_cb = (void*)pyfunc;
        /*printf("callback argument: %p\n",pyfunc);*/
        Py_INCREF(pyfunc);
        return 0;
}

};

%typemap (out) const char* get_data {
        $result = PyString_FromStringAndSize($1,arg1->len); // blah
}

%extend payload {
const char* get_data(void) {
        return self->data;
}
};

