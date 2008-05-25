OBJECTS = $(SOURCES:.c=.o)
SOURCES = nfq.c nfq_utils.c nfq_common.c
HEADERS = nfq.h nfq_utils.h nfq_common.h

SWIG = swig
LOCAL_PKGCONFIG_PATH = /home/pollux/prefix/lib/pkgconfig/
PKGCONFIG = pkg-config

NFQUEUE_INCLUDE = `PKG_CONFIG_PATH=$(LOCAL_PKGCONFIG_PATH) $(PKGCONFIG) libnetfilter_queue --cflags`
NFQUEUE_LIBS = `PKG_CONFIG_PATH=$(LOCAL_PKGCONFIG_PATH) $(PKGCONFIG) libnetfilter_queue --libs`

NFQUEUE_LOCATION = /home/pollux/prefix/include

CFLAGS = $(NFQUEUE_INCLUDE)
LIBS = $(NFQUEUE_LIBS)

PYTHON_CFLAGS = $(CFLAGS) `python2.4-config --cflags`
PYTHON_LIBS = $(LIBS) `python2.4-config --libs`

PERL_CFLAGS = $(CFLAGS) `perl -MExtUtils::Embed -e ccopts`
PERL_LIBS = $(LIBS) `perl -MExtUtils::Embed -e ldopts`

PYTHON_LIB = python/_nfqueue.so
PERL_LIB = perl/nfqueue.so

all: $(PYTHON_LIB) $(PERL_LIB)
	@echo "don't forget to export LD_LIBRARY_PATH=/home/pollux/prefix/lib/"

$(PYTHON_LIB): $(OBJECTS) python/libnetfilter_queue_python.o
	gcc -shared -fpic $(PYTHON_LIBS) -o $@ $^

$(PERL_LIB): $(OBJECTS) perl/libnetfilter_queue_perl.o
	gcc -shared -fpic $(PERL_LIBS) -o $@ $^

perl/libnetfilter_queue_perl.c: libnetfilter_queue.i libnetfilter_queue_perl.i
	[ -d perl ] || mkdir perl; \
	$(SWIG) -perl -o $@ -I$(NFQUEUE_LOCATION) $<

python/libnetfilter_queue_python.c: libnetfilter_queue.i libnetfilter_queue_python.i
	[ -d python ] || mkdir python; \
	$(SWIG) -python -o $@ -I$(NFQUEUE_LOCATION) $<

python/libnetfilter_queue_python.o: python/libnetfilter_queue_python.c
	$(CC) -c -o $@ $(PYTHON_CFLAGS) -I. -I.. $<

perl/libnetfilter_queue_perl.o: perl/libnetfilter_queue_perl.c
	$(CC) -c -o $@ $(PERL_CFLAGS) -I. -I.. $<

clean:
	rm -f $(OBJECTS) python/libnetfilter_queue_python.c python/libnetfilter_queue_python.o perl/libnetfilter_queue_perl.c perl/libnetfilter_queue_perl.o $(PYTHON_LIB) $(PERL_LIB)

