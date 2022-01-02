include_guard()

# Project Directories
set(JGD_PROJECT_CMAKE_DIR "${PROJECT_SOURCE_DIR}/cmake")
set(JGD_PROJECT_DATA_DIR "${PROJECT_SOURCE_DIR}/data")
set(JGD_PROJECT_TESTS_DIR "${PROJECT_SOURCE_DIR}/tests")
set(JGD_PROJECT_DOCS_DIR "${PROJECT_SOURCE_DIR}/docs")

# ConfigureDirectories
set(JGD_CONFIG_HEADER_DESTINATION "${CMAKE_BINARY_DIR}/${PROJECT_NAME}")
set(JGD_CONFIG_PKG_FILE_DESTINATION "${CMAKE_BINARY_DIR}/${PROJECT_NAME}")

# Install Directories
include(GNUInstallDirs)
if(${PROJECT_NAME}_VERSION)
  set(_name_version "${PROJECT_NAME}-${${PROJECT_NAME}_VERSION}")
else()
  set(_name_version "${PROJECT_NAME}")
endif()

# location to install cmake modules
set(JGD_INSTALL_CMAKE_DESTINATION
    "${CMAKE_INSTALL_DATAROOTDIR}/cmake/${_name_version}")

# interface include directory for exported targets.
set(JGD_INSTALL_INTERFACE_INCLUDE_DIR
    "${CMAKE_INSTALL_INCLUDEDIR}/${_name_version}")

#
# Sets the variable specified by OUT_VAR to the installation directory
# destination for public header files. Defined as a function because the path
# depends on the component, if any, and the presence of version. This
# destination contains the include prefix that consumers will use
# (#include<foo/bar/file.hpp>), unlike JGD_INSTALL_INTERFACE_INCLUDE_DIR,
# thereby giving a direct path to where the appropriate header can be installed.
#
# Arguments:
#
# COMPONENT: one-value arg; the component to which the headers that will be
# installed in this location belong. Optional
#
# OUT_VAR: one-value arg; the name of the output variable which will store the
# header installation directory.
#
function(jgd_install_include_destination)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "OUT_VAR;COMPONENT" ARGUMENTS
                      "${ARGN}")
  jgd_validate_arguments(KEYWORDS "OUT_VAR")

  set(include_dir "${JGD_INSTALL_INTERFACE_INCLUDE_DIR}")

  if(NOT "${_name_version}" STREQUAL "${PROJECT_NAME}")
    string(APPEND include_dir "/${PROJECT_NAME}")
  endif()

  if(ARGS_COMPONENT AND (NOT "${ARGS_COMPONENT}" STREQUAL "${PROJECT_NAME}"))
    string(APPEND include_dir "/${ARGS_COMPONENT}")
  endif()

  set(${ARGS_OUT_VAR}
      "${include_dir}"
      PARENT_SCOPE)
endfunction()
