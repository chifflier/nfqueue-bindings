PREFIX = /usr/local
CMAKE_OPTIONS = -DDEBUG=1 -DCMAKE_VERBOSE_MAKEFILE=0 -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=$(PREFIX)
CMAKE_EXTRA_OPTIONS =
BUILD_DIR = build

all:
	[ -d $(BUILD_DIR) ] || mkdir $(BUILD_DIR); \
	cd $(BUILD_DIR) && cmake $(CMAKE_OPTIONS) $(CMAKE_EXTRA_OPTIONS) .. && $(MAKE)

install: all
	cd $(BUILD_DIR) && $(MAKE) install

test:

clean:
	rm -rf $(BUILD_DIR)
