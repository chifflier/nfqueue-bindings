cmake_minimum_required(VERSION 2.4)

STRING(COMPARE EQUAL "${CMAKE_SOURCE_DIR}" "${CMAKE_BINARY_DIR}" insource)
IF(insource)
  MESSAGE(FATAL_ERROR "nfqueue-bindings requires an out of source build. Please create a separate build directory and run 'cmake path_to_nfqueue_bindings [options]' there.")
ENDIF(insource)

FIND_PACKAGE(SWIG REQUIRED)
INCLUDE(${SWIG_USE_FILE})

INCLUDE(UsePkgConfig)
PKGCONFIG(libnetfilter_queue LIBNFQ_INCLUDE_DIR LIBNFQ_LINK_DIR LIBNFQ_LINK_FLAGS LIBNFQ_CFLAGS)

IF (NOT LIBNFQ_INCLUDE_DIR)
  MESSAGE(FATAL_ERROR "libnetfilter_queue was not found")
ENDIF (NOT LIBNFQ_INCLUDE_DIR)

ADD_SUBDIRECTORY(python)
ADD_SUBDIRECTORY(perl)


