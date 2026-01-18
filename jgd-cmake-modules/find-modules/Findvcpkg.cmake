#[=======================================================================[.rst:

Findvcpkg
---------------

:github:`find-modules/Findvcpkg`

A CMake `find module
<https://cmake.org/cmake/help/latest/manual/cmake-developer.7.html#find-modules>`_ used to find the
installed `vcpkg <https://vcpkg.io>`_ package manager executable, the `vcpkg-tool
<https://github.com/microsoft/vcpkg-tool>`_. A vcpkg installation contains the `pacakge index
<https://github.com/microsoft/vcpkg>`_, in the form of a git repository, and the actual `vcpkg-tool
<https://github.com/microsoft/vcpkg-tool>`_, which is primarily an executable to interact with
packages. This module provides access to the vcpkg executable via CMake targets and variables.

Cache Variables
~~~~~~~~~~~~~~~~

:cmake:variable:`vcpkg_EXECUTABLE`
  Absolute path to the found vcpkg executable, used to minimize repeated searches
  with repeated find_package(vcpkg) calls. This value can be queried from the target's
  *IMPORTED_LOCATION* property.

Result Variables
~~~~~~~~~~~~~~~~

:cmake:variable:`vcpkg_FOUND`
  Boolean indicating whether the requested version of vcpkg was found.

:cmake:variable:`vcpkg_VERSION`
  The found vcpkg executable version in the form *<year>-<month>-<day>-<hash>*,
  which is composed of the date and commit hash of the vcpkg-tool build.

Imported Targets
~~~~~~~~~~~~~~~~

vcpkg::tool
  The vcpkg executable and usage requirements bundled as a CMake target.
  Has the *IMPORTED_LOCATION* property set to the full executable path.

Examples
~~~~~~~~

.. code-block:: cmake

  find_package(vcpkg REQUIRED)

  add_custom_target(show-installed
    COMMAND vcpkg::tool search
    COMMENT "List installed vcpkg packages"
    USES_TERMINAL)

Where vcpkg's version does not comply with find_package()'s accepted version format
(``major[.minor[.patch[.tweak]]]``), a specific version *CANNOT* be provided:

.. code-block:: cmake

  # invalid
  find_package(vcpkg 2025-07-21-d4b65a2b83ae6c3526acd1c6f3b51aff2a884533)


#]=======================================================================]

include(FindPackageHandleStandardArgs)

block(PROPAGATE vcpkg_FOUND vcpkg_VERSION)

find_program(
  vcpkg_EXECUTABLE
  NAMES vcpkg
  DOC "Path to vcpkg executable")
mark_as_advanced(vcpkg_EXECUTABLE)

if(vcpkg_EXECUTABLE) 
  execute_process(
    COMMAND "${vcpkg_EXECUTABLE}" --version
    OUTPUT_VARIABLE version_stdout
    ERROR_VARIABLE version_stderr
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  # version output is multiple lines, the first of which is as follows:
  # vcpkg package management program version 2025-07-21-d4b65a2b83ae6c3526acd1c6f3b51aff2a884533
  if(version_stderr)
    message(WARNING
      "Failed to determine vcpkg executable version (${vcpkg_EXECUTABLE})! Error:\n"
      "${version_stderr}")
  else()
    string(REGEX MATCH "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[a-z0-9]+" vcpkg_VERSION "${version_stdout}")
    if(NOT vcpkg_VERSION)
      message(WARNING
        "vcpkg's version output is not recognized by this find module (${version_stdout})!)")
    endif()
  endif()
else()
  unset(vcpkg_VERSION)
endif()

# vcpkg_FOUND and vcpkg_FOUND automatically set
find_package_handle_standard_args(
  vcpkg 
  VERSION_VAR vcpkg_VERSION
  REQUIRED_VARS vcpkg_EXECUTABLE)

if(vcpkg_FOUND AND NOT TARGET vcpkg::tool)
  add_executable(vcpkg::tool IMPORTED GLOBAL)
  set_target_properties(vcpkg::tool PROPERTIES IMPORTED_LOCATION "${vcpkg_EXECUTABLE}")
endif()

endblock()
