PREFIX = /usr/local
CMAKE_OPTIONS = -DDEBUG=1 -DCMAKE_VERBOSE_MAKEFILE=0 -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=$(PREFIX)

all:
	[ -d build ] || mkdir build; \
	cd build && cmake $(CMAKE_OPTIONS) .. && $(MAKE)

install: all
	cd build && $(MAKE) install

clean:
	rm -rf build
