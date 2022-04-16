include_guard()

include(JgdParseArguments)
include(JgdFileNaming)
include(JgdStandardDirs)
include(JgdCanonicalStructure)
include(JgdExpandDirectories)
include(JgdSeparateList)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# Used to only install each project's main package config and version files once
set(_LAST_INSTALLED_PROJECT)

# TODO: - each target can have a pkg-config file - the project definitely needs
# to install the root package config file - the includes above are possibly all
# not necessary

# For each target, searches appropriate paths for pkg config files and sets
# variable specified by out_var to a list of config-files to install
function(_jgd_pkg_configuration_files targets out_var configure_first)
  set(install_cmake_files)

  # searches for file_name in standard cmake source locations
  macro(_search target configure_first)

    jgd_pkg_config_file_name(${comp_arg} OUT_VAR config_file_name)

    if(configure_first)
      set(in_config_file "${config_file_name}${JGD_IN_FILE_EXTENSION}")
      string(PREPEND in_config_file "${JGD_PROJECT_CMAKE_DIR}/")
      if(NOT EXISTS "${in_config_file}")
        message(
          FATAL_ERROR "Cannot configure a package config file for project "
                      "${PROJECT_NAME}. Could not find file ${in_config_file}.")
      endif()

    endif()

    # search for main package config-file
    set(config_pkg_file)
    set(search_paths "${JGD_CMAKE_DESTINATION}/${config_file_name}"
                     "${JGD_PROJECT_CMAKE_DIR}/${config_file_name}")
    foreach(search_path ${search_paths})
      if(EXISTS "${search_path}")
        set(${out_var} "${search_path}")
        return()
      endif()
    endforeach()

    message(
      FATAL_ERROR
        "Unable to install a config-file package without a config file. "
        "Could not find the file ${config_file_name} in any of ${search_paths}."
    )
  endmacro()

  # Add the mandatory project's package config file
  _search(${config_file_name} config_pkg_file)
  list(APPEND install_cmake_files "${config_pkg_file}")

  # Add any additional component-specific config files
  foreach(target ${targets})

  endforeach()

  # Set Result
  set(${out_var}
      "${install_cmake_files}"
      PARENT_SCOPE)
endfunction()

#
# Installs a config-file package and its associated artifacts.  The provided
# TARGETS, HEADERS, and CMAKE_MODULES will be installed under the COMPONENT
# provided, or the default global component of PROJECT_NAME. Prior to
# installing, any TARGETS provided are exported under the namespace
# 'PROJECT_NAME::'. If HEADERS is provided, these exported targets will have
# their INTERFACE_INCLUDE_DIRECTORIES property set to JGD_INSTALL_INCLUDE_DIR,
# such that consumers can use the interface headers.
#
# Multiple calls to this function can be made to install various components, but
# each call expects an appropriately named config-file to be present. All file
# names follow those in JgdFileNaming and installation locations follow those in
# JgdStandardDirs.
#
# Arguments:
#
# COMPONENT: one-value arg; the package component currently being installed.
# Artifacts will be installed under this component. Optional - PROJECT_NAME will
# be used, if not provided.
#
# TARGETS: multi-value arg; the targets to install. The target's headers will
# not automatically be installed, they must be provided through HEADERS.
# Optional.
#
# HEADERS: multi-value arg; list of the interface header files of the TARGETS,
# which will be installed. Relative paths are evaluated with respect to
# CMAKE_CURRENT_SOURCE_DIR, as defined by CMake's install() command. If any of
# the provided paths are directories, the entire recursive directory contents
# will be installed, limited to files that meet JGD_HEADER_REGEX. Nested
# directories will be retained in the installed path, but the given directory
# will not.
#
# CMAKE_MODULES: multi-value arg; list of CMake modules to install in addition
# to the project's config package files. Relative paths are evaluated with
# respect to CMAKE_CURRENT_SOURCE_DIR, as defined by CMake's install() command.
# If any of the provided paths are directories, the entire recursive directory
# contents will be installed, limited to files that meed JGD_CMAKE_MODULE_REGEX.
# Nested directories will be retained in the installed path, but the given
# directory will not.
#

#
# Targets' headers will be installed -> all in runtime except private
#

function(jgd_install_config_file_pkg)
  jgd_parse_arguments(
    OPTIONS
    "CONFIGURE_PKG_CONFIGURATION_FILES"
    MULTI_VALUE_KEYWORDS
    "TARGETS;CMAKE_MODULES"
    REQUIRES_ANY
    "TARGETS;CMAKE_MODULES"
    ARGUMENTS
    "${ARGN}")

  # Usage guard
  if(NOT DEFINED ${PROJECT_NAME}_VERSION)
    message(
      AUTHOR_WARNING
        "It's not recommended to install a config file package without a "
        "project version, as consumers won't be able to version their "
        "consumption and all versions will be installed into the same directory"
    )
  endif()

  # == Optionally configure the pkg-config file

  # == Install CMake Files==

  # list of cmake files to install at end
  set(install_cmake_files)

  # Package version file
  if(DEFINED ${PROJECT_NAME}_VERSION)
    jgd_pkg_version_file_name(OUT_VAR config_version_file)
    string(PREPEND config_version_file "${CMAKE_CURRENT_BINARY_DIR}/")

    write_basic_package_version_file(
      "${config_version_file}"
      VERSION ${PROJECT_VERSION}
      COMPATIBILITY SameMajorVersion)

    list(APPEND install_cmake_files "${config_version_file}")
  endif()

  # Package config file(s)
  _jgd_pkg_configuration_files("${ARGS_TARGETS}" config_pkg_files)
  list(APPEND install_cmake_files "${config_pkg_files}")

  # Additional cmake modules
  if(ARGS_CMAKE_MODULES)
    jgd_expand_directories(PATHS "${ARGS_CMAKE_MODULES}" OUT_VAR module_files
                           GLOB "*.cmake")
    if(module_files)
      jgd_separate_list(
        IN_LIST
        "${module_files}"
        REGEX
        "${JGD_CMAKE_MODULE_REGEX}"
        TRANSFORM
        "FILENAME"
        OUT_MATCHED
        correct_files
        OUT_UNMATCHED
        incorrect_files)
      if(incorrect_files)
        message(
          AUTHOR_WARNING
            "The function ${CMAKE_CURRENT_FUNCTION} will not install the "
            "following CMake modules, as they don't meet the regex "
            "'${JGD_CMAKE_MODULE_REGEX}'. CMake modules: ${incorrect_files}")
      endif()

      # add only correctly named files to be installed
      list(APPEND install_cmake_files "${correct_files}")
    endif()
  endif()

  # Install all CMake files
  install(
    FILES ${install_cmake_files}
    DESTINATION "${JGD_INSTALL_CMAKE_DESTINATION}"
    COMPONENT ${PROJECT_NAME}_devel)

  # ==  Install Target's Interface Headers ==

  foreach(target ARGS_TARGETS)
    # current target's component
    get_target_property(target_component ${target} COMPONENT)
    if(target_component)
      set(comp_arg COMPONENT ${target_component})
    endif()

    # current target's include directories
    get_target_property(inc_prop ${target} ${target}
                        INTERFACE_INCLUDE_DIRECTORIES)
    string(REGEX REPLACE "\$<BUILD_INTERFACE:|>" "" include_dirs "${inc_prop}")

    # suffix all include dirs with / so only their contents is installed
    list(TRANSFORM include_dirs APPEND "/")

    if(suffixed_include_dirs)
      install(
        DIRECTORY ${include_dirs}
        DESTINATION ${JGD_INSTALL_INCLUDE_DIR}
        FILES_MATCHING
        PATTERN "*${JGD_HEADER_EXTENSION}"
        PATTERN "private" EXCLUDE
        COMPONENT ${PROJECT_NAME}_devel)
    endif()
  endforeach()

  # == Install targets via an export set ==

  if(DEFINED ARGS_TARGETS)
    if(DEFINED ARGS_HEADERS)
      set(includes_dest INCLUDES DESTINATION "${JGD_INSTALL_INCLUDE_DIR}")
    endif()

    install(
      TARGETS ${ARGS_TARGETS}
      EXPORT export_set
      ${includes_dest}
      RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
              COMPONENT ${PROJECT_NAME}_runtime
      LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
              COMPONENT ${PROJECT_NAME}_runtime
              NAMELINK_COMPONENT ${PROJECT_NAME}_devel
      ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
              COMPONENT ${PROJECT_NAME}_devel)

    jgd_pkg_targets_file_name(COMPONENT "${component}" OUT_VAR targets_file)
    install(
      EXPORT export_set
      FILE ${targets_file}
      NAMESPACE ${PROJECT_NAME}::
      DESTINATION "${JGD_INSTALL_CMAKE_DESTINATION}"
      COMPONENT ${PROJECT_NAME}_devel)
  endif()
endfunction()
