# don't use include_guard, as JCM_HEADER_DESTINATION is updated for the current binary dir

include(GNUInstallDirs)

# Project Directories
set(JCM_PROJECT_CMAKE_DIR "${PROJECT_SOURCE_DIR}/cmake")
set(JCM_PROJECT_DATA_DIR "${PROJECT_SOURCE_DIR}/data")
set(JCM_PROJECT_TESTS_DIR "${PROJECT_SOURCE_DIR}/tests")
set(JCM_PROJECT_DOCS_DIR "${PROJECT_SOURCE_DIR}/docs")

# Configure Destination Directories
set(JCM_CMAKE_DESTINATION "${PROJECT_BINARY_DIR}/cmake")
set(JCM_HEADER_DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")

# Install Directories
if (DEFINED PROJECT_VERSION)
  set(_jcm_name_version "${PROJECT_NAME}-${PROJECT_VERSION}")
else ()
  set(_jcm_name_version "${PROJECT_NAME}")
endif ()

# location to install cmake modules
set(JCM_INSTALL_CMAKE_DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/cmake/${_jcm_name_version}")

# interface include directory for exported targets in installation
set(JCM_INSTALL_INCLUDE_DIR "${CMAKE_INSTALL_INCLUDEDIR}/${_jcm_name_version}")

set(JCM_INSTALL_DOC_DIR "${CMAKE_INSTALL_DATAROOTDIR}/doc/${_jcm_name_version}")

unset(_jcm_name_version)
