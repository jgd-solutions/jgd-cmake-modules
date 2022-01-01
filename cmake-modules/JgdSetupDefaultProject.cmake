include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdStandardDirs)

#
# This macro sets up a basic CMake project. It sets default target properties,
# handles tests and docs options, and adds default subdirectories following
# JGD's C++ project layout conventions. It does not create the project, as CMake
# doesn't support the project() command via a macro.
#
# Call this macro in the top-level CMakeLists.txt to create a new, default
# project following JGD's default conventions.
#
# Arguments:
#
# COMPONENTS: muli-value arg; list of components that the project encapsulates.
# Used to derive source directories to add as subdirectories, following JGD's
# C++ project layout conventions. Is optional, and shouldn't be used if the
# project doesn't contain any components, or subdirectories aren't to be added
# by this call (ADD_SUBDIRECTORIES isn't provided).
#
# ADD_SUBDIRECTORIES: option; if defined, will cause the function to add
# subdirectories in accordance with JGD's project structure and any COMPONENTS
# provided
#
# WITH_TESTS: option; if defined, will setup automatied testing
#
# WITH_DOCS: option; if defined, will setup documentation generation
#
# WITH_IPO: option; if defined, will enable interprocedural optimization
#
# CONFIGURE_HEADER: option; if defined, will configure a project configuration
# header from an appropriately named input file in the project's cmake directory
#
# CONFIGURE_PKG_CONFIG_FILES: option; if defined, will configure config-file
# package files from the appropriately named input files in the project's cmake
# directory for the project and all provided COMPONENTS.
#
macro(JGD_SETUP_DEFAULT_PROJECT)
  jgd_parse_arguments(
    OPTIONS
    "ADD_SUBDIRECTORIES"
    "WITH_TESTS"
    "WITH_DOCS"
    "WITH_IPO"
    "CONFIGURE_CONFIG_HEADER"
    "CONFIGURE_PKG_CONFIG_FILES"
    MULTI_VALUE_KEYWORDS
    "COMPONENTS"
    ARGUMENTS
    "${ARGN}")

  jgd_validate_arguments()
  if(DEFINED ARGS_COMPONENTS AND NOT DEFINED ARGS_ADD_SUBDIRECTORIES)
    message(
      SEND_ERROR
        "COMPONENTS was provided but ADD_SUBDIRECTORIES option was not "
        "provided. COMPONENTS have no affect.")
  endif()

  if(NOT PROJECT_NAME)
    message(
      FATAL_ERROR
        "A project must be defined to setup a default project. Call CMake's"
        "project() command prior to using jgd_setup_default_project.")
  endif()

  # Start Project Definition

  # default target property values

  # cmake-lint: disable=C0103
  set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
  if(EXISTS "${JGD_PROJECT_CMAKE_DIR}")
    list(APPEND CMAKE_MODULE_PATH "${JGD_PROJECT_CMAKE_DIR}")
  endif()

  include(CTest)
  set(JGD_PROJECT_COMPONENTS "${ARGS_COMPONENTS}")
  list(PREPEND JGD_PROJECT_COMPONENTS "${PROJECT_NAME}")

  if(ARGS_CONFIGURE_CONFIG_HEADER)
    jgd_config_header_file_name(OUT_VAR header_name)
    jgd_config_header_in_file_name(OUT_VAR in_header_file)
    string(PREPEND in_header_file "${JGD_PROJECT_CMAKE_DIR}/")
    if(NOT EXISTS "${in_header_file}")
      messag(FATAL_ERROR "Cannot configure a configuration header for project "
             "${PROJECT_NAME}. Could not find file ${in_header_file}.")
    endif()

    configure_file("${in_header_file}" "${PROJECT_NAME}/${header_name}" @ONLY)
  endif()

  if(ARGS_CONFIGURE_PKG_CONFIG_FILES)
    include(JgdFileNaming)
    foreach(component "${JGD_PROJECT_COMPONENTS}")
      jgd_config_pkg_file_name(COMPONENT "${component}" OUT_VAR
                               config_file_name)
      jgd_config_pkg_in_file_name(COMPONENT "${component}" OUT_VAR
                                  in_config_file)
      string(PREPEND in_config_file "${JGD_PROJECT_CMAKE_DIR}/")
      if(NOT EXISTS "${in_config_file}")
        messag(
          FATAL_ERROR "Cannot configure a package config file for project "
          "${PROJECT_NAME}. Could not find file ${in_config_file} for "
          "component ${component}.")
      endif()

      configure_file("${in_config_file}" "${config_file_name}" @ONLY)
    endforeach()
  endif()

  if(ARGS_WITH_IPO)
    include(JgdEnableDefaultIPO)
    jgd_enable_default_ipo()
  endif()

  if(ARGS_ADD_SUBDIRECTORIES)
    include(JgdAddDefaultSourceSubdirectories)
    if(DEFINED ARGS_COMPOENTS)
      set(comps_args "COMPONENTS ${ARGS_COMPONENTS}")
    endif()
    jgd_add_default_source_subdirectories(PROJECT ${PROJECT_NAME} ${comps_args})
  endif()

  if(ARGS_WITH_TESTS)
    include(JgdSetupTests)
    jgd_setup_tests()
  endif()

  if(ARGS_WITH_DOCS)
    include(JgdSetupDocs)
    jgd_setup_docs()
  endif()

endmacro()
