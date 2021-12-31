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
# project following JGD's default conventions. No project version is specified,
# as that is to be managed by conan, and installation directives aren't added,
# as conan can generate those.
#
# Arguments:
#
# PROJECT: one value arg; the name of the project to setup and the source
# subdirectory to add if no COMPONENTS are specified and ADD_SUBDIRECTORIES is
# defined
#
# COMPONENTS: muli value arg; list of components that the PROJECT encapsulates.
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
# WITHOUT_IPO: option; if defined, will disable interprocedural optimization
#
# WITH_CONFIG_HEADER: options; if defined, will create a configuration header
# from an appropriately named input file in the project's cmake directory
#
macro(JGD_SETUP_DEFAULT_PROJECT)
  jgd_parse_arguments(
    OPTIONS
    "ADD_SUBDIRECTORIES;WITH_TESTS;WITH_DOCS;WITHOUT_IPO;WITH_CONFIG_HEADER"
    ONE_VALUE_KEYWORDS
    "PROJECT"
    MULTI_VALUE_KEYWORDS
    "COMPONENTS"
    ARGUMENTS
    "${ARGN}")

  # Argument Validation
  jgd_validate_arguments(KEYWORDS "PROJECT")
  if(DEFINED ARGS_COMPONENTS AND NOT DEFINED ARGS_ADD_SUBDIRECTORIES)
    message(
      SEND_ERROR
        "COMPONENTS was provided to ${CMAKE_CURRENT_FUNCTION} but "
        "ADD_SUBDIRECTORIES option was not provided. COMPONENTS have no affect."
    )
  endif()

  # Validate environment
  if(NOT ${PROJECT_NAME} STREQUAL ${ARGS_PROJECT})
    message(
      FATAL_ERROR
        "Project provided to ${CMAKE_CURRENT_FUNCTION}, ${ARGS_PROJECT} "
        "doesn't match current CMake project.")
  endif()

  # Start Project Definition

  # default target property values

  # cmake-lint: disable=C0103
  set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
  if(EXISTS "${JGD_PROJECT_CMAKE_DIR }")
    list(APPEND CMAKE_MODULE_PATH "${JGD_PROJECT_CMAKE_DIR}")
  endif()

  enable_language(CXX)
  include(CTest)

  if(ARGS_WITH_CONFIG_HEADER)
    configure_file("${PROJECT_SOURCE_DIR}/cmake/${PROJECT_NAME}_config.hpp.in"
                   "${PROJECT_NAME}/${PROJECT_NAME}_config.hpp" @ONLY)
  endif()

  if(NOT ARGS_WITHOUT_IPO)
    include(JgdEnableDefaultIPO)
    jgd_enable_default_ipo()
  endif()

  if(ARGS_ADD_SUBDIRECTORIES)
    include(JgdAddDefaultSourceSubdirectories)
    if(DEFINED ARGS_COMPOENTS)
      set(comps_args "COMPONENTS ${ARGS_COMPONENTS}")
    endif()
    jgd_add_default_source_subdirectories(PROJECT ${ARGS_PROJECT} ${comps_args})
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
