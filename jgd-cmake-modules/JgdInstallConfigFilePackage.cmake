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
    OPTIONS "CONFIGURE_PACKAGE_CONFIG_FILES"
    MULTI_VALUE_KEYWORDS "TARGETS;CMAKE_MODULES"
    REQUIRES_ANY "TARGETS;CMAKE_MODULES"
    ARGUMENTS "${ARGN}")

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
  function(_jgd_get_package_config_file provided_component out_var)
    if (provided_component)
      set(comp_arg COMPONENT ${provided_component})
    else()
      unset(comp_arg)
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
        IN_LIST "${module_files}"
        REGEX "${JGD_CMAKE_MODULE_REGEX}"
        TRANSFORM "FILENAME"
        OUT_MATCHED correct_files
        OUT_UNMATCHED incorrect_files)
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

  # == Install targets via export sets ==

  foreach (target ${ARGS_TARGETS})
    unset(target_component)
    unset(comp_arg)
    get_target_property(target_component ${target} COMPONENT)
    if (target_component)
      set(comp_arg COMPONENT ${target_component})
    endif ()

    get_target_property(aliased ${target} ALIASED_TARGET)
    if (aliased)
      set(target ${aliased})
    endif ()

    jgd_package_targets_file_name(${comp_arg} OUT_VAR targets_file)
    cmake_path(GET targets_file STEM export_set_name)

    get_target_property(interface_header_sets ${target} INTERFACE_HEADER_SETS)
    set(file_set_args)
    if(interface_header_sets)
      foreach (interface_header_set ${interface_header_sets})
        set(file_set_args ${file_set_args} FILE_SET ${interface_header_set} DESTINATION "${JGD_INSTALL_INCLUDE_DIR}")
      endforeach ()
    endif()

    install(
      TARGETS ${target}
      EXPORT ${export_set_name}
      RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
      COMPONENT ${PROJECT_NAME}_runtime
      LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
      COMPONENT ${PROJECT_NAME}_runtime
      NAMELINK_COMPONENT ${PROJECT_NAME}_devel
      ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
      COMPONENT ${PROJECT_NAME}_devel
      ${file_set_args}
      INCLUDES DESTINATION "${JGD_INSTALL_INCLUDE_DIR}"
    )

    install(
      EXPORT ${export_set_name}
      NAMESPACE ${PROJECT_NAME}::
      DESTINATION "${JGD_INSTALL_CMAKE_DESTINATION}"
      COMPONENT ${PROJECT_NAME}_devel)
  endforeach ()

  # == Install project licenses ==

  function(install_licenses license_glob dest_suffix)
    file(GLOB license_files LIST_DIRECTORIES false "${PROJECT_SOURCE_DIR}/${license_glob}")
    foreach (license_file ${license_files})
      cmake_path(GET license_file FILENAME file_name)
      while (IS_SYMLINK "${license_file}")
        file(READ_SYMLINK "${license_file}" license_file)
      endwhile ()

      if (NOT IS_ABSOLUTE "${license_file}")
        string(PREPEND license_file "${PROJECT_SOURCE_DIR}/")
      endif ()

      if (EXISTS "${license_file}")
        install(FILES "${license_file}" DESTINATION "${JGD_INSTALL_DOC_DIR}/${dest_suffix}" RENAME "${file_name}")
      else ()
        message(WARNING "The license ${file_name} links to a file that doesn't exist: ${license_file}")
      endif ()
    endforeach ()
  endfunction()

  install_licenses("LICENSE*" "")
  install_licenses("licenses/*" "licenses")
endfunction()
