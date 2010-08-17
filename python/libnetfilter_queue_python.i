
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
                p->nfad = nfad;
                payload_obj = SWIG_NewPointerObj((void*) p, SWIGTYPE_p_payload, 0 /* | SWIG_POINTER_OWN */);
                arglist = Py_BuildValue("(N)",payload_obj);
                result = PyEval_CallObject(func,arglist);
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

        return nfq_set_verdict(qh, id, NF_ACCEPT, 0, NULL);
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

