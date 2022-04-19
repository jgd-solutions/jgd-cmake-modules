include_guard()

include(JgdParseArguments)
include(JgdFileNaming)
include(JgdStandardDirs)
include(JgdCanonicalStructure)
include(JgdConfigureFiles)
include(JgdExpandDirectories)
include(JgdSeparateList)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)


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

function(jgd_install_config_file_package)
  jgd_parse_arguments(
    OPTIONS
    "CONFIGURE_PACKAGE_CONFIG_FILES"
    ONE_VALUE_KEYWORDS
    "HEADER_EXCLUDE_REGEX"
    MULTI_VALUE_KEYWORDS
    "TARGETS;CMAKE_MODULES"
    REQUIRES_ANY
    "TARGETS;CMAKE_MODULES"
    ARGUMENTS
    "${ARGN}")

  # Usage guard
  if (NOT DEFINED ${PROJECT_NAME}_VERSION)
    message(
      AUTHOR_WARNING
      "It's not recommended to install a config file package without a "
      "project version, as consumers won't be able to version their "
      "consumption and all versions will be installed into the same directory"
    )
  endif ()

  # Package version file
  if (DEFINED ${PROJECT_NAME}_VERSION)
    jgd_package_version_file_name(OUT_VAR config_version_file)

    write_basic_package_version_file(
      "${JGD_CMAKE_DESTINATION}/${config_version_file}"
      VERSION ${PROJECT_VERSION}
      COMPATIBILITY SameMajorVersion)
    list(APPEND install_cmake_files "${config_version_file}")
  endif ()

  # == Install CMake Files==

  set(install_cmake_files) # list of cmake files to install at end

  # Function to configure and find package config file for components or project
  function(_jgd_get_package_config_file component out_var)
    if (component)
      set(comp_arg COMPONENT ${component})
    endif ()
    jgd_package_config_file_name(${comp_arg} OUT_VAR config_file_name)

    if (DEFINED ARGS_CONFIGURE_PACKAGE_CONFIG_FILES)
      set(in_config_file "${config_file_name}${JGD_IN_FILE_EXTENSION}")
      string(PREPEND in_config_file "${JGD_PROJECT_CMAKE_DIR}/")
      if (EXISTS "${in_config_file}")
        jgd_configure_package_config_file(${comp_arg})
      else ()
        message(
          FATAL_ERROR "Cannot configure a package config file for ${component} of project "
          "${PROJECT_NAME}. Could not find file ${in_config_file}.")
      endif ()
    endif ()

    # search for package config-file
    set(config_pkg_file)
    set(search_paths "${JGD_CMAKE_DESTINATION}/${config_file_name}"
      "${JGD_PROJECT_CMAKE_DIR}/${config_file_name}")
    foreach (search_path ${search_paths})
      if (EXISTS "${search_path}")
        set(${out_var} "${search_path}" PARENT_SCOPE)
        return()
      endif ()
    endforeach ()

    message(
      FATAL_ERROR
      "Unable to install a config-file package without a config file. "
      "Could not find the file ${config_file_name} in any of ${search_paths}."
    )
  endfunction()

  # Resolve components' package config files, append to cmake files to be installed
  foreach (target ${ARGS_TARGETS})
    get_target_property(component ${target} COMPONENT)
    if (NOT DEFINED component)
      continue()
    endif ()

    _jgd_get_package_config_file(${component} component_config_file)
    list(APPEND install_cmake_files "${component_config_file}")
  endforeach ()

  # Append project's main package config file to cmake files to be installed
  _jgd_get_package_config_file("" component_config_file)
  list(APPEND install_cmake_files "${component_config_file}")

  # Additional cmake modules for project
  if (DEFINED ARGS_CMAKE_MODULES)
    jgd_expand_directories(PATHS "${ARGS_CMAKE_MODULES}" OUT_VAR module_files GLOB "*.cmake")
    list(REMOVE_ITEM module_files ${install_cmake_modules}) # ignore config package files

    if (module_files)
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
      if (incorrect_files)
        message(
          AUTHOR_WARNING
          "The function ${CMAKE_CURRENT_FUNCTION} will not install the "
          "following CMake modules, as they don't meet the regex "
          "'${JGD_CMAKE_MODULE_REGEX}'. CMake modules: ${incorrect_files}")
      endif ()

      # add only correctly named files to be installed
      list(APPEND install_cmake_files "${correct_files}")
    endif ()
  endif ()


  # Install all CMake files
  install(
    FILES ${install_cmake_files}
    DESTINATION "${JGD_INSTALL_CMAKE_DESTINATION}"
    COMPONENT ${PROJECT_NAME}_devel)

  # ==  Install Target's Interface Headers ==

  foreach (target ${ARGS_TARGETS})
    get_target_property(target_component ${target} COMPONENT)
    if (target_component)
      set(comp_arg COMPONENT ${target_component})
    endif ()

    # current target's include directories
    get_target_property(inc_prop ${target} ${target} INTERFACE_INCLUDE_DIRECTORIES)
    string(REGEX REPLACE "\$<BUILD_INTERFACE:|>" "" include_dirs "${inc_prop}")

    # suffix all include dirs with / so only their contents is installed
    list(TRANSFORM include_dirs APPEND "/")

    if (DEFINED ARGS_HEADER_EXCLUDE_REGEX)
      set(exclude_arg REGEX "${ARGS_HEADER_EXCLUDE_REGEX}" EXCLUDE)
    endif ()

    if (include_dirs)
      install(
        DIRECTORY ${include_dirs}
        DESTINATION ${JGD_INSTALL_INCLUDE_DIR}
        FILES_MATCHING
        PATTERN "*${JGD_HEADER_EXTENSION}"
        PATTERN "*private*" EXCLUDE
        ${exclude_arg}
        COMPONENT ${PROJECT_NAME}_devel)
    endif ()
  endforeach ()

  # == Install targets via an export set ==

  if (DEFINED ARGS_TARGETS)
    install(
      TARGETS ${ARGS_TARGETS}
      EXPORT export_set
      INCLUDES DESTINATION "${JGD_INSTALL_INCLUDE_DIR}"
      RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
      COMPONENT ${PROJECT_NAME}_runtime
      LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
      COMPONENT ${PROJECT_NAME}_runtime
      NAMELINK_COMPONENT ${PROJECT_NAME}_devel
      ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
      COMPONENT ${PROJECT_NAME}_devel)


    jgd_package_targets_file_name(OUT_VAR targets_files)
    foreach (target ${ARGS_TARGETS})
      get_target_property(component ${target} COMPONENT)
      if (NOT DEFINED component)
        continue()
      endif ()

      jgd_package_targets_file_name(COMPONENT ${component} OUT_VAR targets_file)
      list(APPEND targets_files "${targets_file}")
    endforeach ()

    install(
      EXPORT export_set
      FILES ${targets_files}
      NAMESPACE ${PROJECT_NAME}::
      DESTINATION "${JGD_INSTALL_CMAKE_DESTINATION}"
      COMPONENT ${PROJECT_NAME}_devel)
  endif ()
endfunction()
