include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdFileNaming)
include(JgdStandardDirs)
include(CMakePackageConfigHelpers)

#
# Private function to the module. For each path in PATHS, if the path is a
# directory, the enclosed files matching GLOB will be expanded into the list
# specified by OUT_FILES. These expanded paths will be given relative to
# CMAKE_CURRENT_SOURCE_DIR. Paths that refer directly to files will be directly
# added to the list specified by OUT_FILES.
#
# Arguments:
#
# PATHS: multi-value arg; list of input paths to expand
#
# OUT_FILES: one-value arg; the name of the variable that will store the list of
# file paths.
#
# GLOB: one-value arg; the GLOBBING expression for files within directory paths.
# The final globbing expression, used to get files within the directory path, is
# directory_path/GLOB
#
function(_expand_dirs)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "OUT_FILES;GLOB" MULTI_VALUE_KEYWORDS
                      "PATHS" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "PATHS;OUT_FILES;GLOB")

  set(file_paths)
  foreach(in_path ${ARGS_PATHS})
    # if(IS_DIRECTORY) isn't well defined for rel paths
    file(REAL_PATH "${in_path}" full_path)

    if(IS_DIRECTORY "${full_path}")
      file(
        GLOB_RECURSE expand_files FOLLOW_SYMLINKS
        LIST_DIRECTORIES TRUE
        RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
        "${full_path}/${ARGS_GLOB}")
      if(expand_files)
        list(APPEND file_paths ${expand_files})
      endif()
    else()
      list(APPEND file_paths "${full_path}")
    endif()
  endforeach()

  set(${ARGS_OUT_FILES}
      ${file_paths}
      PARENT_SCOPE)
endfunction()

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
# HEADERS: multi-value arg; list of the interface header files of the TARGETS
# which will be installed. Relative paths are evaluated with respect to
# CMAKE_CURRENT_SOURCE_DIR, as defined by CMake's install() command. If any of
# the provided paths are directories, the entire recursive directory contents
# will be installed, limited to files with the extension '.hpp'. Nested
# directories will be retained in the installed path, but the given directory
# will not.
#
# CMAKE_MODULES: multi-value arg; list of CMake modules to install in addition
# to the project's config package files. Relative paths are evaluated with
# respect to CMAKE_CURRENT_SOURCE_DIR, as defined by CMake's install() command.
# If any of the provided paths are directories, the entire recursive directory
# contents will be installed, limited to files with the extension '.cmake'.
# Nested directories will be retained in the installed path, but the given
# directory will not.
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
    _expand_dirs(PATHS ${ARGS_HEADERS} OUT_FILES header_files GLOB "*.hpp")
    if(header_files)
      install(
        FILES ${header_files}
        DESTINATION "${include_dst}"
        COMPONENT ${component})
    endif()
  endif()

  # Install cmake modules, including config package modules
  jgd_config_pkg_file_name(COMPONENT "${component}" OUT_VAR config_file_name)

  set(config_pkg_file "${JGD_CONFIG_PKG_FILE_DESTINATION}/${config_file_name}")
  if(NOT EXISTS "${config_pkg_file}")
    set(config_pkg_file "${JGD_PROJECT_CMAKE_DIR}/${config_file_name}")
    if(NOT EXISTS "${config_pkg_file}")
      message(
        FATAL_ERROR
          "Unable to install the targets ${ARGS_TARGETS} without a config "
          "file. Could not find the file ${config_file_name} in "
          "${JGD_CONFIG_PKG_FILE_DESTINATION} or ${JGD_PROJECT_CMAKE_DIR}.")
    endif()
  endif()

  set(config_files "${config_pkg_file}")

  if(do_version_file)
    list(APPEND config_files "${config_version_file}")
  endif()

  if(ARGS_CMAKE_MODULES)
    _expand_dirs(PATHS ${ARGS_CMAKE_MODULES} OUT_FILES module_files GLOB
                 "*.cmake")
    if(module_files)
      list(APPEND config_files ${module_files})
    endif()
  endif()

  install(
    FILES ${config_files}
    DESTINATION "${JGD_INSTALL_CMAKE_DESTINATION}"
    COMPONENT ${component})

  # Install targets via an export set
  install(
    TARGETS ${ARGS_TARGETS}
    EXPORT export_set
    INCLUDES
    DESTINATION "${JGD_INSTALL_INTERFACE_INCLUDE_DIR}"
    COMPONENT ${component})
  jgd_config_pkg_targets_file_name(COMPONENT "${component}" OUT_VAR
                                   targets_file)

  install(
    EXPORT export_set
    FILE ${targets_file}
    NAMESPACE ${PROJECT_NAME}::
    DESTINATION "${JGD_INSTALL_CMAKE_DESTINATION}"
    COMPONENT ${component})

endfunction()
