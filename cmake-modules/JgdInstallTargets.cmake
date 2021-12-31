include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdConfigPackageFileNames)
include(JgdStandardDirs)
include(CMakePackageConfigHelpers)

#
# A convenience function to create an executable and add it as a test in one
# command.  An executable with name EXECUTABLE will be created from the sources
# provided to SOURCES. This executable will then be registered as a test with
# name NAME, or EXECUTABLE, if NAME is not provided.
#
# Arguments:
#
# EXECUTABLE: one value arg; the name of the test executable to generate.
#
# NAME: one value arg; the name of the test to register with CTest. Will be set
# to EXECUTABLE, if not provided.
#
# SOURCES: multi value arg; the sources to create EXECUTABLE from.
#
# LIBS: multi value arg; list of libraries to privately link against the test
# executable. Commonly the library under test. Optional.
#
function(jgd_install_targets)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "COMPONENT" MULTI_VALUE_KEYWORDS
                      "TARGETS;HEADERS;CMAKE_MODULES" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "TARGETS")

  # Setup
  set(do_version_file FALSE)
  if(${PROJECT_NAME}_VERSION
     AND (NOT ARGS_COMPONENT)
     AND (NOT "${ARGS_COMPONENT}" STREQUAL "${PROJECT_NAME}"))
    set(do_version_file TRUE)
  endif()

  set(config_version_file)
  if(do_version_file)
    jgd_config_version_file_name(OUT_VAR config_version_file)
    string(PREPEND config_version_file "${CMAKE_CURRENT_BINARY_DIR}/")
    write_basic_package_version_file(
      "${CMAKE_CURRENT_BINARY_DIR}/${config_version_file}"
      VERSION ${${PROJECT_NAME}_VERSION}
      COMPATIBILITY AnyNewerVersion)
  endif()

  set(component "${PROJECT_NAME}")
  if(ARGS_COMPONENT)
    set(component "${ARGS_COMPONENT}")
  endif()

  # Install headers
  if(ARGS_HEADERS)
    jgd_install_include_dir(COMPONENT "${component}" OUT_VAR include_dir)
    install(
      FILES "${ARGS_HEADERS}"
      DESTINATION "${include_dir}"
      COMPONENT "${component}")
  endif()

  # Install cmake modules, including config package modules
  jgd_config_file_name(COMPONENT "${component}" OUT_VAR config_file_name)
  set(config_pkg_file "${CMAKE_CURRENT_BINARY_DIR}/${config_file_name}")
  if(NOT EXISTS "${config_pkg_file}")
    set(config_pkg_file "${JGD_PROJECT_CMAKE_DIR}/${config_file_name}")
    if(NOT_EXISTS "${config_pkg_file}")
      message(
        FATAL_ERROR
          "Unable to install the targets ${ARGS_TARGETS} without a config file."
          "Could not find the file ${config_file_name} in "
          "${CMAKE_CURRENT_BINARY_DIR} or ${JGD_PROJECT_CMAKE_DIR}.")
    endif()
  endif()

  set(config_files "${config_pkg_file}")

  if(do_version_file)
    list(APPEND config_files "${config_version_file}")
  endif()
  if(ARGS_CMAKE_MODULES)
    list(APPEND config_files "${ARGS_CMAKE_MODULES}")
  endif()

  install(FILES "${config_files}"
          DESTINATION "${JGD_INSTALL_CMAKE_DESTINATION}")

  # Install targets via an export set
  install(
    TARGETS "${ARGS_TARGETS}"
    EXPORT export_set
    INCLUDES
    DESTINATION "${JGD_INSTALL_INTERFACE_INCLUDE_DIR}")
  jgd_config_targets_file_name(COMPONENT "${component}" OUT_VAR targets_file)

  install(
    EXPORT export_set
    FILE ${targets_file}
    NAMESPACE ${PROJECT_NAME}::
    DESTINATION "${JGD_INSTALL_CMAKE_DESTINATION}"
    COMPONENT ${component})

endfunction()
