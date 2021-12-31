include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdConfigPackageFileNames)
include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

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

  set(name_version "${PROJECT_NAME}")
  set(config_version_file "")
  if(do_version_file)
    jgd_config_version_file_name(OUT_VAR config_version_file)
    string(APPEND name_version "-${${PROJECT_NAME}_VERSION")

    write_basic_package_version_file(
      "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}/${config_version_file}"
      VERSION ${${PROJECT_NAME}_VERSION}
      COMPATIBILITY AnyNewerVersion)
  endif()

  set(component "${PROJECT_NAME}")
  if(ARGS_COMPONENT)
    set(component "${ARGS_COMPONENT}")
  endif()

  # Install headers
  if(ARGS_HEADERS)
    set(include_dir
        "${CMAKE_INSTALL_INCLUDEDIR}/${name_version}/${PROJECT_NAME}")
    if(ARGS_COMPONENT)
      string(APPEND include_dir "/${ARGS_COMPONENT}")
    endif()

    install(
      FILES "${ARGS_HEADERS}"
      DESTINATION "${include_dir}"
      COMPONENT "${component}")
  endif()

  # Install cmake modules, including config package modules
  set(cmake_destination "${CMAKE_INSTALL_DATAROOTDIR}/cmake/${name_version}")

  jgd_config_file_name(COMPONENT "${component}" OUT_VAR config_file)
  set(config_pkg_file
      "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}/${config_file}")
  if(NOT EXISTS "${config_pkg_file}")
    set(config_pkg_file "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
    message(
      FATAL_ERROR
        "Unable to install the targets ${ARGS_TARGETS} without a config file.
    Expected ${config_pkg_file}, but the file could not be found. You may ")
  endif()

  set(config_files "${config_pkg_file}")

  if(do_version_file)
    list(APPEND config_files
         "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}/${config_version_file}")
  endif()
  if(ARGS_CMAKE_MODULES)
    list(APPEND config_files "${ARGS_CMAKE_MODULES}")
  endif()

  install(FILES "${config_files}" DESTINATION ${cmake_destination})

  # Install targets via an export set
  install(TARGETS "${ARGS_TARGETS}" EXPORT export_set)
  jgd_config_targets_file_name(COMPONENT "${component}" OUT_VAR targets_file)

  install(
    EXPORT export_set
    FILE ${targets_file}
    NAMESPACE ${PROJECT_NAME}::
    DESTINATION "${cmake_destination}"
    COMPONENT ${component})

endfunction()
