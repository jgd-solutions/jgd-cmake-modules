#[=======================================================================[.rst:

FindClangFormat
-------------------

A CMake `find module
<https://cmake.org/cmake/help/latest/manual/cmake-developer.7.html#find-modules>`_ used to find the
`ClangFormat <https://clang.llvm.org/docs/ClangFormat.html>`_ code formatter. This module provides
access to the `clang-format` executable via CMake targets and variables. When a version is provided
to :cmake:command:`find_package`, this find-module will also consider version-suffixed clang-format
executables. See :ref:`Examples<ExamplesAnchor>` below.

Clang offers a `config-file package
<https://github.com/llvm/llvm-project/blob/main/clang/cmake/modules/ClangConfig.cmake.in>`_, which
can be used to locate ClangFormat from CMake. However, this requires having the *dev* packages
of LLVM & Clang installed. Additionally, LLVM often isn't a dependency of ClangFormat packages,
which are frequently distributed independently.

Cache Variables
~~~~~~~~~~~~~~~~

:cmake:variable:`ClangFormat_EXECUTABLE`
  Path to found clang-foramt executable

Result Variables
~~~~~~~~~~~~~~~~

:cmake:variable:`ClangFormat_FOUND`
  True if the clang-format executable was found

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
  The clang-format executable, as an imported CMake target

.. _ExamplesAnchor:

Examples
~~~~~~~~

.. code-block:: cmake

  find_package(ClangFormat)

.. code-block:: cmake

  # additionally considers executables "clang-format-14" and "clang-format-14.0"

  find_package(ClangFormat 14.0 REQUIRED)


#]=======================================================================]

include(FindPackageHandleStandardArgs)

if(ClangFormat_FIND_VERSION)
  set(_ClangFormat_versioned_names
    "clang-format-${ClangFormat_FIND_VERSION_MAJOR}"
    "clang-format-${ClangFormat_FIND_VERSION_MAJOR}.${ClangFormat_FIND_VERSION_MINOR}"
    "clang-format-${ClangFormat_FIND_VERSION}"
  )
endif()


find_program(
  ClangFormat_EXECUTABLE
  NAMES "clang-format" ${_ClangFormat_versioned_names}
  DOC "Path to clang-format executable"
)
unset(_ClangFormat_versioned_names)
mark_as_advanced(Sphinx_EXECUTABLE)

# executable version
if(ClangFormat_EXECUTABLE)
  execute_process(
    COMMAND "${ClangFormat_EXECUTABLE}" --version
    OUTPUT_VARIABLE _ClangFormat_version_stdout
    ERROR_VARIABLE _ClangFormat_version_stderr
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )

  if(_ClangFormat_version_stderr)
    message(WARNING
      "Failed to determine version of clang-format executable (${ClangFormat_EXECUTABLE})! Error:\n"
      "${_ClangFormat_version_stderr}"
    )
  elseif(NOT _ClangFormat_version_stdout MATCHES
          "clang-format(-[\\.0-9]+)? version [0-9]+\\.[0-9]+\\.[0-9]+")
    message(WARNING
      "clang-format's version output is not recognized by this find module"
      " (${_ClangFormat_version_stdout})!)"
    )
  else()
    # extract version from stdout
    string(
      REGEX REPLACE "clang-format.* version " ""
      ClangFormat_VERSION "${_ClangFormat_version_stdout}"
    )
    string(REPLACE "." ";" _ClangFormat_version_components "${ClangFormat_VERSION}")
    list(GET _ClangFormat_version_components 0 ClangFormat_VERSION_MAJOR)
    list(GET _ClangFormat_version_components 1 ClangFormat_VERSION_MINOR)
    list(GET _ClangFormat_version_components 2 ClangFormat_VERSION_PATCH)
  endif()

  unset(_ClangFormat_version_components)
  unset(_ClangFormat_version_stderr)
  unset(_ClangFormat_version_stdout)
endif()

find_package_handle_standard_args(ClangFormat
  FOUND_VAR ClangFormat_FOUND
  REQUIRED_VARS ClangFormat_EXECUTABLE
  VERSION_VAR ClangFormat_VERSION
)

if (ClangFormat_FOUND AND NOT TARGET clang::format)
  add_executable(clang::format IMPORTED)
  set_target_properties(clang::format PROPERTIES IMPORTED_LOCATION "${ClangFormat_EXECUTABLE}")
endif()
