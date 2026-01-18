#[=======================================================================[.rst:

FindClangFormat
---------------

:github:`find-modules/FindClangFormat`

A CMake `find module
<https://cmake.org/cmake/help/latest/manual/cmake-developer.7.html#find-modules>`_ used to find the
`ClangFormat <https://clang.llvm.org/docs/ClangFormat.html>`_ code formatter. This module provides
access to the `clang-format` executable via CMake targets and variables. When a version is provided
to :cmake:command:`find_package`, this find-module will also consider version-suffixed clang-format
executables. See :ref:`Examples<ExamplesAnchor>` below.

Clang offers a `config-file package
<https://github.com/llvm/llvm-project/blob/main/clang/cmake/modules/ClangConfig.cmake.in>`_, which
can be used to locate ClangFormat from CMake. However, this requires having the *dev* packages
of LLVM & Clang installed. Additionally, LLVM often isn't a dependency of Clang(Format) packages,
which are frequently distributed independently.

Cache Variables
~~~~~~~~~~~~~~~~

:cmake:variable:`ClangFormat_EXECUTABLE`
  Absolute path to the found clang-format executable, used to minimize repeated searches
  with repeated find_package(ClangFormat) calls. This value can be queried from the target's
  *IMPORTED_LOCATION* property.

Result Variables
~~~~~~~~~~~~~~~~

:cmake:variable:`ClangFormat_FOUND`
  Boolean indicating whether the requested version of clang-format was found.

:cmake:variable:`ClangFormat_VERSION`
  The found version, where version is in the form *<major>.<minor>.<patch>*

:cmake:variable:`ClangFormat_VERSION_MAJOR`
  The found major version

:cmake:variable:`ClangFormat_VERSION_MINOR`
  The found minor version

:cmake:variable:`ClangFormat_VERSION_PATCH`
  The found patch version

Imported Targets
~~~~~~~~~~~~~~~~

clang::format
  The clang-format executable, as an imported CMake target.
  Has the *IMPORTED_LOCATION* property set.

.. _ExamplesAnchor:

Examples
~~~~~~~~

.. code-block:: cmake

  find_package(ClangFormat)

  jcm_create_clang_format_targets(SOURCE_TARGETS libbbq::libbbq)

.. code-block:: cmake

  # considers executables "clang-format-14.0" and "clang-format-14" before "clang-format"

  find_package(ClangFormat 14.0 REQUIRED)


#]=======================================================================]

include(FindPackageHandleStandardArgs)

block(SCOPE_FOR VARIABLES PROPAGATE ClangFormat_FOUND ClangFormat_VERSION ClangFormat_VERSION_MAJOR ClangFormat_VERSION_MINOR ClangFormat_VERSION_PATCH)

# these version variables are introduced by the find_package call which loaded this find-module
if(ClangFormat_FIND_VERSION)
  set(versioned_names
     "clang-format-${ClangFormat_FIND_VERSION}"
     "clang-format-${ClangFormat_FIND_VERSION_MAJOR}.${ClangFormat_FIND_VERSION_MINOR}"
     "clang-format-${ClangFormat_FIND_VERSION_MAJOR}")
endif()

find_program(
  ClangFormat_EXECUTABLE
  NAMES ${versioned_names} "clang-format"
  DOC "Cached path to clang-format executable for find_package(ClangFormat)")
mark_as_advanced(ClangFormat_EXECUTABLE)

# executable version
if(ClangFormat_EXECUTABLE)
  execute_process(
    COMMAND "${ClangFormat_EXECUTABLE}" --version
    OUTPUT_VARIABLE version_stdout
    ERROR_VARIABLE version_stderr
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  if(version_stderr)
    message(WARNING
      "Failed to determine version of clang-format executable (${ClangFormat_EXECUTABLE})! Error:\n"
      "${version_stderr}")
  elseif(NOT version_stdout MATCHES
          "clang-format(-[\\.0-9]+)? version [0-9]+\\.[0-9]+\\.[0-9]+")
    message(WARNING
      "clang-format's version output is not recognized by this find module (${version_stdout})!)")
  else()
    # extract version from stdout
    string(
      REGEX REPLACE ".*clang-format.* version " ""
      ClangFormat_VERSION "${version_stdout}")
    string(REPLACE "." ";" version_components "${ClangFormat_VERSION}")
    list(GET version_components 0 ClangFormat_VERSION_MAJOR)
    list(GET version_components 1 ClangFormat_VERSION_MINOR)
    list(GET version_components 2 ClangFormat_VERSION_PATCH)
  endif()
endif()

# ClangFormat_FOUND and CLANGFORMAT_FOUND automatically set
find_package_handle_standard_args(ClangFormat
  REQUIRED_VARS ClangFormat_EXECUTABLE
  VERSION_VAR ClangFormat_VERSION)

if(ClangFormat_FOUND AND NOT TARGET clang::format)
  add_executable(clang::format IMPORTED GLOBAL)
  set_target_properties(clang::format PROPERTIES IMPORTED_LOCATION "${ClangFormat_EXECUTABLE}")
endif()

endblock()