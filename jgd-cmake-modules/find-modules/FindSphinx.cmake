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
  The found sphinx version, where version is in the form *<major>.<minor>.<patch>*

:cmake:variable:`Sphinx_VERSION_MAJOR`
  The found sphinx major version

:cmake:variable:`Sphinx_VERSION_MINOR`
  The found sphinx minor version

:cmake:variable:`Sphinx_VERSION_PATCH`
  The found sphinx patch version

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
  cmake_path(GET Python_EXECUTABLE PARENT_PATH _Python_interp_dir)
  set(_Sphinx_bin_hint "${_Python_interp_dir}")
  set(_Sphinx_scripts_hint "${_Python_interp_dir}/Scripts")
  unset(_Python_interp_dir)
else()
  unset(_Sphinx_bin_hint)
  unset(_Sphinx_scripts_hint)
endif()

find_program(
  Sphinx_EXECUTABLE
  NAMES sphinx-build sphinx-build2 sphinx-build3
  HINTS "${_Sphinx_bin_hint}" "${_Sphinx_scripts_hint}"
  DOC "Path to Sphinx documentation builder executable")
unset(_Sphinx_bin_hint)
unset(_Sphinx_scripts_hint)
mark_as_advanced(Sphinx_EXECUTABLE)

# executable version
if(Sphinx_EXECUTABLE)
  execute_process(
    COMMAND "${Sphinx_EXECUTABLE}" --version
    OUTPUT_VARIABLE _Sphinx_version_stdout
    ERROR_VARIABLE _Sphinx_version_stderr
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  if(_Sphinx_version_stderr)
    message(WARNING
      "Failed to determine version of sphinx build executable (${Sphinx_EXECUTABLE})! Ensure any "
      "pertinent Python virtual environment is activated. Error: ${_Sphinx_version_stderr}")
  elseif(NOT _Sphinx_version_stdout MATCHES "sphinx-build[23]? [0-9]+\\.[0-9]+\\.[0-9]+")
    message(WARNING
      "Sphinx's version output is not recognized by this find module (${_Sphinx_version_stdout})!)")
  else()
    # extract version from stdout
    string(REGEX REPLACE ".*sphinx-build[23]? " "" Sphinx_VERSION "${_Sphinx_version_stdout}")
    string(REPLACE "." ";" _Sphinx_version_components "${Sphinx_VERSION}")
    list(GET _Sphinx_version_components 0 Sphinx_VERSION_MAJOR)
    list(GET _Sphinx_version_components 1 Sphinx_VERSION_MINOR)
    list(GET _Sphinx_version_components 2 Sphinx_VERSION_PATCH)
  endif()

  unset(_Sphinx_version_components)
  unset(_Sphinx_version_stderr)
  unset(_Sphinx_version_stdout)
endif()

string(CONCAT _Sphinx_failure_message
  "Sphinx is not installed or a Python virtual environment may not have been activated.\n"
  "'Sphinx_ROOT' can be set to refer to a Sphinx installation root, even within a virtual environment. "
  "Ex. `cmake -B build -D Sphinx_ROOT=/home/me/.venv/bin`")

find_package_handle_standard_args(Sphinx
  FOUND_VAR Sphinx_FOUND
  REQUIRED_VARS Sphinx_EXECUTABLE
  VERSION_VAR Sphinx_VERSION
  REASON_FAILURE_MESSAGE ${_Sphinx_failure_message})
unset(_Sphinx_failure_message)

if(Sphinx_FOUND AND NOT TARGET Sphinx::build)
  add_executable(Sphinx::build IMPORTED)
  set_target_properties(Sphinx::build PROPERTIES IMPORTED_LOCATION "${Sphinx_EXECUTABLE}")
endif()
