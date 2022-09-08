#[=======================================================================[.rst:
FindSphinx
-------------------

A CMake `find module
<https://cmake.org/cmake/help/latest/manual/cmake-developer.7.html#find-modules>`_ used to find the
`Sphinx <https://www.sphinx-doc.org/en/master/#>`_ documentation generator. Sphinx provides an
executable to build documentation, commonly called *sphinx-build*. This module provides access to
it, or similarly named executables, via CMake targets and variables.

Cache Variables
~~~~~~~~~~~~~~~~

:cmake:variable:`Sphinx_EXECUTABLE`
  Path to found sphinx build executable

Result Variables
~~~~~~~~~~~~~~~~

:cmake:variable:`Sphinx_FOUND`
  True if the sphinx build executable was found

:cmake:variable:`Sphinx_VERSION`
  The found sphinx version

Imported Targets
~~~~~~~~~~~~~~~~

Sphinx::build
  The sphinx build executable (sphinx-build, sphinx-build2, sphinx-build3)

Examples
~~~~~~~~

.. code-block:: cmake

  find_package(Sphinx REQUIRED)

#]=======================================================================]


include(FindPackageHandleStandardArgs)

# use python interpreter path as a base of search
find_package(Python COMPONENTS Interpreter)
if(Python_Interpreter_FOUND)
  get_filename_component(_pyinterp_dir "${Python_EXECUTABLE}" DIRECTORY)
  set(_sphinx_hints  "${_pyinterp_dir}" "${_pyinterp_dir}/bin" "${_pyinterp_dir}/Scripts")
  unset(_pyinterp_dir)
endif()

find_program(
  Sphinx_EXECUTABLE
  NAMES sphinx-build sphinx-build2 sphinx-build3
  HINTS "${_sphinx_hints}"
  DOC "Path to Sphinx documentation builder executable"
)
unset(_sphinx_hints)
mark_as_advanced(Sphinx_EXECUTABLE)

# executable version
if(Sphinx_EXECUTABLE)
  execute_process(
    COMMAND "${Sphinx_EXECUTABLE}" --version
    OUTPUT_VARIABLE _sphinx_version_stdout
    ERROR_VARIABLE _sphinx_version_stderr
  )

  if(_sphinx_version_stderr)
    message(WARNING
      "Failed to determine version of sphinx build executable (${Sphinx_EXECUTABLE})! Error:\n"
      "${_sphinx_version_stderr}"
    )
  elseif(NOT _sphinx_version_stdout MATCHES "sphinx-build[23]? [0-9].[0-9].[0-9]")
    message(WARNING
      "Sphinx's version output is not recognized by this find module (${_sphinx_version_stdout})!)"
    )
  else()
    # extract version from stdout
    string(STRIP "${_sphinx_version_stdout}" _sphinx_version_stdout)
    string(REGEX REPLACE "sphinx-build[23]? " "" Sphinx_VERSION "${_sphinx_version_stdout}")
    string(REPLACE "." ";" _sphinx_version_components "${Sphinx_VERSION}")
    list(GET _sphinx_version_components 0 Sphinx_VERSION_MAJOR)
    list(GET _sphinx_version_components 1 Sphinx_VERSION_MINOR)
    list(GET _sphinx_version_components 2 Sphinx_VERSION_PATCH)
  endif()

  unset(_sphinx_version_components)
  unset(_sphinx_version_stderr)
  unset(_sphinx_version_stdout)
endif()

find_package_handle_standard_args(Sphinx
  FOUND_VAR Sphinx_FOUND
  REQUIRED_VARS Sphinx_EXECUTABLE
  VERSION_VAR Sphinx_VERSION
)

message(STATUS "VERSION VAR: ${Sphinx_VERSION}")

if (Sphinx_FOUND AND NOT TARGET Sphinx::build)
  add_executable(Sphinx::build IMPORTED)
  set_target_properties(Sphinx::build PROPERTIES IMPORTED_LOCATION "${Sphinx_EXECUTABLE}")
endif()
