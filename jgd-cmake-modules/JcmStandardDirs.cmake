#[=======================================================================[.rst:

JcmStandardDirs
---------------

Provies variables defining standard project directories for the source, build, and install trees.
All installation paths are versioned such that multiple versions of the same project can be
installed in the same location.
The following variables are set:

- :cmake:variable:`JCM_PROJECT_CMAKE_DIR` Location where CMake code, such as config-files and
  modules, reside.
- :cmake:variable:`JCM_PROJECT_DATA_DIR` Location where non-code files that still need to be tracked
  by revision control reside
- :cmake:variable:`JCM_PROJECT_TESTS_DIR` Location where tests that are not unit-tests reside. For
  example, integration, performance, smoke tests, etc.
- :cmake:variable:`JCM_PROJECT_DOCS_DIR` Location where project documentation resides
- :cmake:variable:`JCM_PROJECT_LICENSES_DIR` Location where project licenses reside. A single
  license single file can be placed at the project root, though.
- :cmake:variable:`JCM_CMAKE_DESTINATION` Destination in the build tree for cmake modules. For
  example, configured cmake modules are configured to this location.
- :cmake:variable:`JCM_HEADER_DESTINATION` Destination in the build tree for header files. For
  example, configured header files are configured to this location. This variable is updated based
  on :cmake:variable:`CMAKE_CURRENT_BINARY_DIR`, and therefore depends on the location of its
  inclusion.
- :cmake:variable:`JCM_INSTALL_CMAKE_DESTINATION` Destination in the install tree for cmake modules.
- :cmake:variable:`JCM_INSTALL_INCLUDE_DIR` Base directory for installed headers. This path is what
  should be added to consumer's include paths to use the installed headers.
  :cmake:command:`jcm_install_config_file_package` automatically does this. Refers to a versioned form
  of :cmake:variable:`CMAKE_INSTALL_DOCDIR` from *GNUInstallDirs*.
- :cmake:variable:`JCM_INSTALL_DOC_DIR` Root directory for installed docs and related files. Refers
  to a versioned form of :cmake:variable:`CMAKE_INSTALL_DOCDIR` from *GNUInstallDirs*.

#]=======================================================================]

include(GNUInstallDirs)

# Project Directories
set(JCM_PROJECT_CMAKE_DIR "${PROJECT_SOURCE_DIR}/cmake")
set(JCM_PROJECT_DATA_DIR "${PROJECT_SOURCE_DIR}/data")
set(JCM_PROJECT_TESTS_DIR "${PROJECT_SOURCE_DIR}/tests")
set(JCM_PROJECT_DOCS_DIR "${PROJECT_SOURCE_DIR}/docs")
set(JCM_PROJECT_LICENSES_DIR "${PROJECT_SOURCE_DIR}/licenses")

# Configure Destination Directories
set(JCM_CMAKE_DESTINATION "${PROJECT_BINARY_DIR}/cmake")
set(JCM_HEADER_DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")

# Install Directories
if(DEFINED PROJECT_VERSION)
  set(_jcm_name_version "${PROJECT_NAME}-${PROJECT_VERSION}")
else()
  set(_jcm_name_version "${PROJECT_NAME}")
endif()

# location to install cmake modules
set(JCM_INSTALL_CMAKE_DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/cmake/${_jcm_name_version}")

# interface include directory for exported targets in installation
set(JCM_INSTALL_INCLUDE_DIR "${CMAKE_INSTALL_INCLUDEDIR}/${_jcm_name_version}")

set(JCM_INSTALL_DOC_DIR "${CMAKE_INSTALL_DATAROOTDIR}/doc/${_jcm_name_version}")

unset(_jcm_name_version)
