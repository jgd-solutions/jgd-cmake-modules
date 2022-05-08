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

  set(install_cmake_files) # list of cmake files to install at end

  # Package version file
  if (DEFINED ${PROJECT_NAME}_VERSION)
    jgd_package_version_file_name(OUT_VAR config_version_file)
    set(config_version_file "${JGD_CMAKE_DESTINATION}/${config_version_file}")

    write_basic_package_version_file(
      "${config_version_file}"
      VERSION ${PROJECT_VERSION}
      COMPATIBILITY SameMajorVersion)
    list(APPEND install_cmake_files "${config_version_file}")
  endif ()

  # == Install CMake Files==

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
          FATAL_ERROR "Cannot configure a package config file for ${comp_arg} of project "
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
    if (NOT component)
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
    list(REMOVE_ITEM module_files ${install_cmake_files}) # ignore config package files

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
    unset(target_component)
    unset(comp_arg)
    unset(exclude_arg)
    get_target_property(target_component ${target} COMPONENT)
    if (target_component)
      set(comp_arg COMPONENT ${target_component})
    endif ()

    # current target's include directories
    get_target_property(inc_prop ${target} INTERFACE_INCLUDE_DIRECTORIES)
    string(REGEX REPLACE "\\$<BUILD_INTERFACE:|>" "" include_dirs "${inc_prop}")

    # convert each to absolute paths with project name appended, to ignore project dirs
    get_target_property(source_dir ${target} SOURCE_DIR)
    set(abs_include_dirs)
    foreach (include_dir ${include_dirs})
      if (IS_ABSOLUTE "${include_dir}")
        list(APPEND abs_include_dirs "${include_dir}/${PROJECT_NAME}/")
      else ()
        list(APPEND abs_include_dirs "${source_dir}/${include_dir}/${PROJECT_NAME}/")
      endif ()
    endforeach ()

    if (DEFINED ARGS_HEADER_EXCLUDE_REGEX)
      jgd_separate_list(IN_LIST "${abs_include_dirs}"
        REGEX "${ARGS_HEADER_EXCLUDE_REGEX}"
        OUT_UNMATCHED abs_include_dirs)
    endif ()

    install(DIRECTORY ${abs_include_dirs}
      DESTINATION "${JGD_INSTALL_INCLUDE_DIR}/${PROJECT_NAME}"
      COMPONENT ${PROJECT_NAME}_devel
      FILES_MATCHING PATTERN "*${JGD_HEADER_EXTENSION}"
      PATTERN "CMakeFiles" EXCLUDE)
  endforeach ()

  # == Install targets via an export set ==

  set(install_targets)
  foreach (target ${ARGS_TARGETS})
    get_target_property(aliased ${target} ALIASED_TARGET)
    if (aliased)
      list(APPEND install_targets ${aliased})
    else ()
      list(APPEND install_targets ${target})
    endif ()
  endforeach ()

  if (DEFINED ARGS_TARGETS)
    install(
      TARGETS ${install_targets}
      EXPORT export_set
      INCLUDES DESTINATION "${JGD_INSTALL_INCLUDE_DIR}"
      RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
      COMPONENT ${PROJECT_NAME}_runtime
      LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
      COMPONENT ${PROJECT_NAME}_runtime
      NAMELINK_COMPONENT ${PROJECT_NAME}_devel
      ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
      COMPONENT ${PROJECT_NAME}_devel)

    jgd_package_targets_file_name(OUT_VAR targets_file)
    install(
      EXPORT export_set
      FILE ${targets_file}
      NAMESPACE ${PROJECT_NAME}::
      DESTINATION "${JGD_INSTALL_CMAKE_DESTINATION}"
      COMPONENT ${PROJECT_NAME}_devel)
  endif ()

  # == Install project licenses ==

  # licenses in project root
  file(GLOB license_files LIST_DIRECTORIES false "${PROJECT_SOURCE_DIR}/LICENSE*")
  foreach (license_file ${license_files})
    cmake_path(GET license_file FILENAME file_name)
    while (IS_SYMLINK "${license_file}")
      file(READ_SYMLINK "${license_file}" license_file)
    endwhile ()
    install(FILES "${license_file}" DESTINATION "${JGD_INSTALL_DOC_DIR}" RENAME "${file_name}")
  endforeach ()

  # licenses in dedicated folder
  file(GLOB license_files LIST_DIRECTORIES false "${PROJECT_SOURCE_DIR}/licenses/*")
  foreach (license_file ${license_files})
    cmake_path(GET license_file FILENAME file_name)
    while (IS_SYMLINK "${license_file}")
      file(READ_SYMLINK "${license_file}" license_file)
    endwhile ()
    install(FILES "${license_file}" DESTINATION "${JGD_INSTALL_DOC_DIR}/licenses/" RENAME "${file_name}")
  endforeach ()
endfunction()
