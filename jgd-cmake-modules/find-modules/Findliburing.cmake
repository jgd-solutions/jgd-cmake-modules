#[=======================================================================[.rst:

Findliburing
---------------

:github:`find-modules/Findliburing`

A CMake `find module
<https://cmake.org/cmake/help/latest/manual/cmake-developer.7.html#find-modules>`_ used to find the
installed `liburing <https://github.com/axboe/liburing>`_ Linux library. This module provides access
to the liburing library via CMake targets and variables. This module does not take the target system
(:cmake:variable:`CMAKE_SYSTEM_NAME` `link
<https://cmake.org/cmake/help/latest/variable/CMAKE_SYSTEM_NAME.html>`_) into account. To avoid
searching for liburing on non-Linux machines, explicitly wrap the
:cmake:command:`find_package(liburing)` call in a condition. 

Cache Variables
~~~~~~~~~~~~~~~~

:cmake:variable:`liburing_INCLUDE_DIR`
  Absolute path to the found liburing include directory, used to minimize repeated searches
  with repeated find_package(liburing) calls. This value can be queried from the target's
  *INTERFACE_INCLUDE_DIRECTORIES* property.

:cmake:variable:`liburing_LIBRARY`
  Absolute path to the found liburing shared/static library, used to minimize repeated searches with
  repeated find_package(liburing) calls. This value can be queried from the target's
  *IMPORTED_LOCATION* property.

Result Variables
~~~~~~~~~~~~~~~~

:cmake:variable:`liburing_FOUND`
  Boolean indicating whether the requested version of liburing was found.

:cmake:variable:`liburing_VERSION`
  The found liburing library version in the form *<major>.<minor>*

:cmake:variable:`liburing_VERSION_MAJOR`
  The found liburing library major version as a single integer 

:cmake:variable:`liburing_VERSION_MINOR`
  The found liburing library minor version as a single integer 

Imported Targets
~~~~~~~~~~~~~~~~

liburing::liburing
  The liburing library and usage requirements bundled as a CMake target.
  Has the *INTERFACE_INCLUDE_DIRECTORIES* and *IMPORTED_LOCATION* properties
  set.

Examples
~~~~~~~~

.. code-block:: cmake

  find_package(liburing REQUIRED)

  target_link_libraries(mylib PRIVATE liburing::liburing)

.. code-block:: cmake

  find_package(liburing 2.1...2.11 REQUIRED)


#]=======================================================================]

include(FindPackageHandleStandardArgs)

block(PROPAGATE liburing_FOUND liburing_VERSION liburing_VERSION_MAJOR liburing_VERSION_MINOR)

find_path(liburing_INCLUDE_DIR NAMES liburing.h)
if(NOT liburing_INCLUDE_DIR)
  return()
endif()

find_library(liburing_LIBRARY NAMES uring)
if(NOT liburing_LIBRARY)
  return()
endif()

set(liburing_version_file "${liburing_INCLUDE_DIR}/liburing/io_uring_version.h")
if(EXISTS "${liburing_version_file}") 
  # version components defined in the form:
  #define IO_URING_VERSION_MAJOR 2
  #define IO_URING_VERSION_MINOR 11

  file(STRINGS "${liburing_version_file}" versions REGEX "IO_URING_VERSION_")
  list(LENGTH versions num_version_components)
  if(num_version_components EQUAL 2)
    list(TRANSFORM versions REPLACE "[^0-9]" "")
    list(GET versions 0 liburing_VERSION_MAJOR)
    list(GET versions 1 liburing_VERSION_MINOR)
    string(JOIN "." liburing_VERSION ${versions})
  else()
    message(WARNING
      "Found liburing version file, but it contains unrecognized version format "
      "'${liburing_version_file}': ${versions}")
  endif()

else()
  unset(liburing_VERSION)
endif()

# liburing_FOUND and LIBURING_FOUND automatically set
find_package_handle_standard_args(
  liburing 
  VERSION_VAR liburing_VERSION
  HANDLE_VERSION_RANGE
  REQUIRED_VARS liburing_LIBRARY liburing_INCLUDE_DIR)

if(liburing_FOUND AND NOT TARGET liburing::liburing)
  add_library(liburing::liburing IMPORTED UNKNOWN)
  set_target_properties(liburing::liburing 
    PROPERTIES
      INTERFACE_INCLUDE_DIRECTORIES "${liburing_INCLUDE_DIR}"
      IMPORTED_LOCATION "${liburing_LIBRARY}")
endif()

endblock()
