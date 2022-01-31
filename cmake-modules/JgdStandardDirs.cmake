include_guard()

include(GNUInstallDirs)

# Project Directories
set(JGD_PROJECT_CMAKE_DIR "${PROJECT_SOURCE_DIR}/cmake")
set(JGD_PROJECT_DATA_DIR "${PROJECT_SOURCE_DIR}/data")
set(JGD_PROJECT_TESTS_DIR "${PROJECT_SOURCE_DIR}/tests")
set(JGD_PROJECT_DOCS_DIR "${PROJECT_SOURCE_DIR}/docs")

# ConfigureDirectories
set(JGD_CONFIG_HEADER_DESTINATION "${CMAKE_BINARY_DIR}/${PROJECT_NAME}")
set(JGD_PKG_CONFIG_FILE_DESTINATION "${CMAKE_BINARY_DIR}/${PROJECT_NAME}")

# Install Directories
if(${PROJECT_NAME}_VERSION)
  set(_name_version "${PROJECT_NAME}-${PROJECT_VERSION}")
else()
  set(_name_version "${PROJECT_NAME}")
endif()

# location to install cmake modules
set(JGD_INSTALL_CMAKE_DESTINATION
    "${CMAKE_INSTALL_DATAROOTDIR}/cmake/${_name_version}")

# interface include directory for exported targets.
set(JGD_INSTALL_INTERFACE_INCLUDE_DIR
    "${CMAKE_INSTALL_INCLUDEDIR}/${_name_version}")
