cmake_minimum_required(VERSION 2.8)
PROJECT(np_library_builder)

INCLUDE(${CMAKE_CURRENT_SOURCE_DIR}/LibraryBuilderMacros.cmake)
CHECK_PROJECT_PLATFORM()
FILE(GLOB_RECURSE CMAKELIST_FILES libraries/*/CMakeLists.txt)
FOREACH(CMAKELIST_FILE ${CMAKELIST_FILES})
  MESSAGE(STATUS ${CMAKELIST_FILE})
  GET_FILENAME_COMPONENT(LIB_DIR ${CMAKELIST_FILE} PATH)
  ADD_SUBDIRECTORY(${LIB_DIR})
ENDFOREACH()

# Boost 1.41
# http://softlayer.dl.sourceforge.net/project/boost/boost/1.41.0/boost_1_41_0.tar.bz2
SET(LIBRARY_PROJECT_NAME "Boost")
SET(LIBRARY_PROJECT_VERSION "1.41")
SET(LIBRARY_PROJECT_DOWNLOAD_URL "http://softlayer.dl.sourceforge.net/project/boost/boost/1.41.0/boost_1_41_0.tar.bz2")

BUILD_BOOST_EXTERNAL()

# libusb 1.0.6
# http://cdnetworks-us-2.dl.sourceforge.net/project/libusb/libusb-1.0/libusb-1.0.6/libusb-1.0.6.tar.bz2
SET(LIBRARY_PROJECT_NAME "libusb-1.0")
SET(LIBRARY_PROJECT_VERSION "1.0.6")
SET(LIBRARY_PROJECT_DOWNLOAD_URL "http://cdnetworks-us-2.dl.sourceforge.net/project/libusb/libusb-1.0/libusb-1.0.6/libusb-1.0.6.tar.bz2")

BUILD_AUTOTOOLS_EXTERNAL()

# libusb 0.1.12
# http://cdnetworks-us-1.dl.sourceforge.net/project/libusb/libusb-0.1%20%28LEGACY%29/0.1.12/libusb-0.1.12.tar.gz

SET(LIBRARY_PROJECT_NAME "libusb-0.1")
SET(LIBRARY_PROJECT_VERSION "0.1.12")
SET(LIBRARY_PROJECT_DOWNLOAD_URL "http://cdnetworks-us-1.dl.sourceforge.net/project/libusb/libusb-0.1%20%28LEGACY%29/0.1.12/libusb-0.1.12.tar.gz")

BUILD_AUTOTOOLS_EXTERNAL()

# libftdi 1.17
# http://www.intra2net.com/en/developer/libftdi/download/libftdi-0.17.tar.gz

SET(LIBRARY_PROJECT_NAME "libftdi")
SET(LIBRARY_PROJECT_VERSION "1.17")
SET(LIBRARY_PROJECT_DOWNLOAD_URL "http://www.intra2net.com/en/developer/libftdi/download/libftdi-0.17.tar.gz")
SET(LIBRARY_PROJECT_DEPENDS "libusb-0.1")
BUILD_AUTOTOOLS_EXTERNAL()

# libhid
# http://alioth.debian.org/frs/download.php/1958/libhid-0.2.16.tar.gz
SET(LIBRARY_PROJECT_NAME "libhid")
SET(LIBRARY_PROJECT_VERSION "0.2.16")
SET(LIBRARY_PROJECT_DOWNLOAD_URL "http://alioth.debian.org/frs/download.php/1958/libhid-0.2.16.tar.gz")
SET(LIBRARY_PROJECT_CONFIGURE_OPTIONS "--disable-swig")
SET(LIBRARY_PROJECT_DEPENDS "libusb-0.1")
BUILD_AUTOTOOLS_EXTERNAL()

# liblo
# http://voxel.dl.sourceforge.net/project/liblo/liblo/0.26/liblo-0.26.tar.gz

# SET(LIBRARY_PROJECT_NAME "liblo")
# SET(LIBRARY_PROJECT_VERSION "0.26")
# SET(LIBRARY_PROJECT_DOWNLOAD_URL "http://voxel.dl.sourceforge.net/project/liblo/liblo/0.26/liblo-0.26.tar.gz")

# BUILD_AUTOTOOLS_EXTERNAL()

# pyusb

# flext
