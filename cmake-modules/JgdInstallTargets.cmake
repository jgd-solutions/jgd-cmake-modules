include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdFileNaming)
include(JgdStandardDirs)
include(CMakePackageConfigHelpers)

#
# Executes the appropriate commands to export and install the provided TARGETS
# and install all other associated files, like project CMake modules and
# headers, as a config-file package. The artifacts will be installed under the
# COMPONENT provided, or a default global component with the name PROJECT_NAME.
# All exported TARGETS have the namespace prefix 'PROJECT_NAME::'.
#
# A config-file per target is expected to be present, as it's required for
# config-file packages, and will be installed.  Installation locations follow
# those in JgdStandardDirs and file names follow those in JgdFileNaming.
#
# Arguments:
#
# TARGETS: multi-value arg; the targets to install.
#
# HEADERS: multi-value arg; the interface header files of the TARGETS which will
# be installed.
#
# CMAKE_MODULES: multi-value arg; CMake modules to install, in addition to the
# project's config package files.
#
# COMPONENT: one-value arg; the component under which the artifacts will be
# intalled. Optional - PROJECT_NAME will be used, if not provided.
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
    jgd_config_pkg_version_file_name(OUT_VAR config_version_file)
    string(PREPEND config_version_file "${CMAKE_CURRENT_BINARY_DIR}/")
    write_basic_package_version_file(
      "${config_version_file}"
      VERSION ${${PROJECT_NAME}_VERSION}
      COMPATIBILITY AnyNewerVersion)
  endif()

  set(component "${PROJECT_NAME}")
  if(ARGS_COMPONENT)
    set(component ${ARGS_COMPONENT})
  endif()

  # Install headers
  if(ARGS_HEADERS)
    jgd_install_include_dir(COMPONENT ${component} OUT_VAR include_dir)
    install(
      FILES "${ARGS_HEADERS}"
      DESTINATION "${include_dir}"
      COMPONENT ${component})
  endif()

  # Install cmake modules, including config package modules
  jgd_config_pkg_file_name(COMPONENT "${component}" OUT_VAR config_file_name)
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

  install(
    FILES "${config_files}"
    DESTINATION "${JGD_INSTALL_CMAKE_DESTINATION}"
    COMPONENT ${component})

  # Install targets via an export set
  install(
    TARGETS ${ARGS_TARGETS}
    EXPORT export_set
    INCLUDES
    DESTINATION "${JGD_INSTALL_INTERFACE_INCLUDE_DIR}")
    COMPONENT ${component}
  jgd_config_pkg_targets_file_name(COMPONENT "${component}" OUT_VAR
                                   targets_file)

  install(
    EXPORT export_set
    FILE ${targets_file}
    NAMESPACE ${PROJECT_NAME}::
    DESTINATION "${JGD_INSTALL_CMAKE_DESTINATION}"
    COMPONENT ${component})

endfunction()
