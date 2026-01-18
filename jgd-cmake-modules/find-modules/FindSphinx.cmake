#[=======================================================================[.rst:

FindSphinx
----------

:github:`find-modules/FindSphinx`

A CMake `find module
<https://cmake.org/cmake/help/latest/manual/cmake-developer.7.html#find-modules>`_ used to find the
`Sphinx <https://www.sphinx-doc.org/en/master/#>`_ documentation generator. Sphinx provides an
executable to build documentation, commonly called *sphinx-build*. This module provides access to
it, or similarly named executables, via CMake targets and variables.

Cache Variables
~~~~~~~~~~~~~~~~

:cmake:variable:`Sphinx_EXECUTABLE`
  Absolute path to the found sphinx-build executable, used to minimize repeated searches with
  repeated :cmake:`find_package(Sphinx)` calls. This value can be queried from the target's
  *IMPORTED_LOCATION* property.

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

  jcm_create_sphinx_targets(CONFIGURE_CONF_PY)

#]=======================================================================]

include(FindPackageHandleStandardArgs)

block(SCOPE_FOR VARIABLES PROPAGATE Sphinx_FOUND Sphinx_VERSION Sphinx_VERSION_MAJOR Sphinx_VERSION_MINOR Sphinx_VERSION_PATCH)

# use python interpreter path as a base of search
find_package(Python COMPONENTS Interpreter)
if(Python_Interpreter_FOUND)
  cmake_path(GET Python_EXECUTABLE PARENT_PATH python_interp_dir)
  set(bin_hint "${python_interp_dir}")
  set(scripts_hint "${python_interp_dir}/Scripts")
else()
  unset(bin_hint)
  unset(scripts_hint)
endif()

find_program(
  Sphinx_EXECUTABLE
  NAMES sphinx-build sphinx-build2 sphinx-build3
  HINTS "${bin_hint}" "${scripts_hint}"
  DOC "Path to Sphinx documentation builder executable")
mark_as_advanced(Sphinx_EXECUTABLE)

# executable version
if(Sphinx_EXECUTABLE)
  execute_process(
    COMMAND "${Sphinx_EXECUTABLE}" --version
    OUTPUT_VARIABLE version_stdout
    ERROR_VARIABLE version_stderr
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  if(version_stderr)
    message(WARNING
      "Failed to determine version of sphinx build executable (${Sphinx_EXECUTABLE})! Ensure any "
      "pertinent Python virtual environment is activated. Error: ${version_stderr}")
  elseif(NOT version_stdout MATCHES "sphinx-build[23]? [0-9]+\\.[0-9]+\\.[0-9]+")
    message(WARNING
      "Sphinx's version output is not recognized by this find module (${version_stdout})!)")
  else()
    # extract version from stdout
    string(REGEX REPLACE ".*sphinx-build[23]? " "" Sphinx_VERSION "${version_stdout}")
    string(REPLACE "." ";" version_components "${Sphinx_VERSION}")
    list(GET version_components 0 Sphinx_VERSION_MAJOR)
    list(GET version_components 1 Sphinx_VERSION_MINOR)
    list(GET version_components 2 Sphinx_VERSION_PATCH)
  endif()
endif()

string(CONCAT failure_message
  "Sphinx is not installed or a Python virtual environment may not have been activated.\n"
  "'Sphinx_ROOT' can be set to refer to a Sphinx installation root, even within a virtual env. "
  "Ex. `cmake -B build -D Sphinx_ROOT=/path/to/.venv/bin`")

# Sphinx_FOUND and SPHINX_FOUND automatically set
find_package_handle_standard_args(Sphinx
  REQUIRED_VARS Sphinx_EXECUTABLE
  VERSION_VAR Sphinx_VERSION
  REASON_FAILURE_MESSAGE ${failure_message})

if(Sphinx_FOUND AND NOT TARGET Sphinx::build)
  add_executable(Sphinx::build IMPORTED)
  set_target_properties(Sphinx::build PROPERTIES IMPORTED_LOCATION "${Sphinx_EXECUTABLE}")
endif()

endblock()