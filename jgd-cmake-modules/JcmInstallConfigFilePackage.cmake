include_guard()

#[=======================================================================[.rst:

JcmInstallConfigFilePackage
---------------------------

:github:`JcmInstallConfigFilePackage`

#]=======================================================================]

include(JcmParseArguments)
include(JcmFileNaming)
include(JcmStandardDirs)
include(JcmCanonicalStructure)
include(JcmConfigureFiles)
include(JcmExpandDirectories)
include(JcmListTransformations)
include(JcmSymlinks)
include(JcmTargetNaming)
include(JcmAddOption)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

#[=======================================================================[.rst:

jcm_install_config_file_package
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_install_config_file_package

  .. code-block:: cmake

    jcm_install_config_file_package(
      [CONFIGURE_PACKAGE_CONFIG_FILES]
      <[TARGETS <target>...]
       [CMAKE_MODULES <path>...]
       [INSTALL_LICENSES] >)

Provides ability to consistently and reliably install a project as a config-file package in one
command.  All of the named :cmake:variable:`TARGETS`, :cmake:variable:`CMAKE_MODULES`, and licenses
will be installed to paths provided by `GNUInstallDirs` with appropriate package config-files,
version file, and targets files. Package config-files will be installed from
:cmake:variable:`JCM_PROJECT_CMAKE_DIR` or :cmake:variable:`JCM_INSTALL_CMAKE_DESTINATION`, if they
were configured.


Each target will be installed with an associated targets file. The target will be exported within
the namespace :cmake:`${PROJECT_NAME}::`, which includes the key "::" characters and follows common
conventions. Executables and shared libraries will be installed under the install component
:cmake:`${PROJECT_NAME}_runtime`, while static libraries and headers in the target's *INTERFACE* and
*PUBLIC* header sets will be installed under the :cmake:`${PROJECT_NAME}_devel` install component.
This supports separate runtime and development packages often distributed. Alias targets are
supported (libsample::libsample)

:cmake:variable:`CMAKE_MODULES` will be installed under the :cmake:`${PROJECT_NAME}_devel` install
component. If any of the paths in this list name a directory, the directory will be expanded to all
enclosed files ending in `.cmake`. Relative paths are converted to absolute paths with respect to
:cmake:variable:`CMAKE_CURRENT_SOURCE_DIR`.

Licenses are installed under :cmake:variable:`JCM_INSTALL_DOC_DIR`. Both a root `LICENSE.*` file and
licenses within :cmake:variable:`JCM_PROJECT_LICENSES_DIR` will be installed. Symlinks are followed
until a file is reached, ensuring to install the license file with the original name of the symlink.
Intermediate symlinks are not installed.

By default, installation is only performed when the project is top-level. However, the install
commands of this function can be enabled/disabled using the option
:cmake:variable:`<JCM_PROJECT_PREFIX_NAME>_INSTALL`, also created by this function, allowing users
to override this behaviour.

Parameters
##########

Options
~~~~~~~

:cmake:variable:`CONFIGURE_PACKAGE_CONFIG_FILES`
  When provided, the config-files will be configured using
  :cmake:command:`jcm_configure_package_config_file`

:cmake:variable:`INSTALL_LICENSES`
  Causes this function to install licenses from the paths described above.

Multi Value
~~~~~~~~~~~

:cmake:variable:`TARGETS`
  A list of targets to install.

:cmake:variable:`CMAKE_MODULES`
  Relative or absolute paths to additional CMake modules, or directories containing CMake modules,
  to install.

Examples
########

.. code-block:: cmake

  jcm_install_config_file_package(TARGETS libbbq::libbbq)

.. code-block:: cmake

  jcm_install_config_file_package(
    CONFIGURE_PACKAGE_CONFIG_FILES
    INSTALL_LICENSES
    TARGETS libbbq::core libbbq::meat libbbq::veg
    CMAKE_MODULES "${JCM_PROJECT_CMAKE_DIR}")

#]=======================================================================]
function(jcm_install_config_file_package)
  jcm_parse_arguments(
    OPTIONS "CONFIGURE_PACKAGE_CONFIG_FILES" "INSTALL_LICENSES"
    MULTI_VALUE_KEYWORDS "TARGETS;CMAKE_MODULES"
    REQUIRES_ANY "TARGETS;CMAKE_MODULES;INSTALL_LICENSES"
    ARGUMENTS "${ARGN}")

  # Usage guards
  if(NOT DEFINED ${PROJECT_NAME}_VERSION)
    message(
      AUTHOR_WARNING
      "It's not recommended to install a config file package without a "
      "project version, as consumers won't be able to version their "
      "consumption and all versions will be installed into the same directory")
  endif()

  foreach(target ${ARGS_TARGETS})
    if(NOT TARGET ${target})
      message(
        FATAL_ERROR
        "Cannot install target ${target}. The target does not exist!")
    endif()
  endforeach()

  # Install Option
  jcm_add_option(
    NAME ${JCM_PROJECT_PREFIX_NAME}_CONFIGURE_INSTALL
    DESCRIPTION  "Enables install commands of project ${PROJECT_NAME}"
    TYPE BOOL
    DEFAULT ${PROJECT_IS_TOP_LEVEL})
  if(NOT ${JCM_PROJECT_PREFIX_NAME}_CONFIGURE_INSTALL)
    return()
  endif()

  set(install_cmake_files) # list of cmake files to install at end

  # Package version file
  if(DEFINED ${PROJECT_NAME}_VERSION)
    jcm_package_version_file_name(OUT_VAR config_version_file)
    set(config_version_file "${JCM_CMAKE_DESTINATION}/${config_version_file}")

    write_basic_package_version_file(
      "${config_version_file}"
      VERSION ${PROJECT_VERSION}
      COMPATIBILITY SameMajorVersion)
    list(APPEND install_cmake_files "${config_version_file}")
  endif()

  # == Install CMake Files==

  # Function to configure and find package config file for components or project
  function(_jcm_get_package_config_file provided_component out_var)
    if(provided_component)
      set(comp_arg COMPONENT ${provided_component})
    else()
      unset(comp_arg)
    endif()
    jcm_package_config_file_name(${comp_arg} OUT_VAR config_file_name)

    if(DEFINED ARGS_CONFIGURE_PACKAGE_CONFIG_FILES)
      set(in_config_file "${config_file_name}${JCM_IN_FILE_EXTENSION}")
      string(PREPEND in_config_file "${JCM_PROJECT_CMAKE_DIR}/")

      if(EXISTS "${in_config_file}")
        jcm_configure_package_config_file(${comp_arg} OUT_FILE_VAR configured_out_file)
        set(${out_var} "${configured_out_file}" PARENT_SCOPE)
        return()
      else()
        message(
          FATAL_ERROR "Cannot configure a package config file for ${comp_arg} of project "
          "${PROJECT_NAME}. Could not find file ${in_config_file}.")
      endif()
    endif()

    # search for package config-file
    set(unconfigured_config_file "${JCM_PROJECT_CMAKE_DIR}/${config_file_name}")
    if(EXISTS "${unconfigured_config_file}")
      set(${out_var} "${unconfigured_config_file}" PARENT_SCOPE)
      return()
    endif()

    message(
      FATAL_ERROR
      "Unable to install a config-file package without a config file. "
      "Could not find the file ${unconfigured_config_file}.")
  endfunction()

  # Resolve components' package config files, append to cmake files to be installed
  foreach(target ${ARGS_TARGETS})
    get_target_property(component ${target} COMPONENT)
    if(NOT component)
      continue()
    endif()

    _jcm_get_package_config_file(${component} component_config_file)
    list(APPEND install_cmake_files "${component_config_file}")
  endforeach()

  # Append project's main package config file to cmake files to be installed
  _jcm_get_package_config_file("" component_config_file)
  list(APPEND install_cmake_files "${component_config_file}")

  # Additional cmake modules for project
  if(DEFINED ARGS_CMAKE_MODULES)
    jcm_expand_directories(PATHS "${ARGS_CMAKE_MODULES}" OUT_VAR module_files GLOB "*.cmake")
    list(REMOVE_ITEM module_files ${install_cmake_files}) # ignore config package files

    if(module_files)
      jcm_separate_list(
        INPUT "${module_files}"
        REGEX "${JCM_CMAKE_MODULE_REGEX}"
        TRANSFORM "FILENAME"
        OUT_MATCHED correct_files
        OUT_MISMATCHED incorrect_files)
      if(incorrect_files)
        message(AUTHOR_WARNING
          "The function ${CMAKE_CURRENT_FUNCTION} will not install the "
          "following CMake modules, as they don't meet the regex "
          "'${JCM_CMAKE_MODULE_REGEX}'. CMake modules: ${incorrect_files}")
      endif()

      # add only correctly named files to be installed
      list(APPEND install_cmake_files "${correct_files}")
    endif()
  endif()

  # Install all CMake files
  install(
    FILES ${install_cmake_files}
    DESTINATION "${JCM_INSTALL_CMAKE_DESTINATION}"
    COMPONENT ${PROJECT_NAME}_devel)

  # == Install targets via export sets ==

  foreach(target ${ARGS_TARGETS})
    unset(target_component)
    unset(comp_arg)
    get_target_property(target_component ${target} COMPONENT)
    if(target_component)
      set(comp_arg COMPONENT ${target_component})
    endif()

    jcm_package_targets_file_name(${comp_arg} OUT_VAR targets_file)
    cmake_path(GET targets_file STEM export_set_name)

    jcm_aliased_target(TARGET "${target}" OUT_TARGET target)
    get_target_property(interface_header_sets ${target} INTERFACE_HEADER_SETS)
    set(file_set_args)
    if(interface_header_sets)
      foreach(interface_header_set ${interface_header_sets})
        set(file_set_args ${file_set_args} FILE_SET ${interface_header_set} DESTINATION "${JCM_INSTALL_INCLUDE_DIR}")
      endforeach()
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
      COMPONENT ${PROJECT_NAME}_devel
      INCLUDES DESTINATION "${JCM_INSTALL_INCLUDE_DIR}")

    install(
      EXPORT ${export_set_name}
      NAMESPACE ${PROJECT_NAME}::
      DESTINATION "${JCM_INSTALL_CMAKE_DESTINATION}"
      COMPONENT ${PROJECT_NAME}_devel)
  endforeach()

  # == Install project licenses ==

  function(install_licenses license_glob dest_suffix)
    file(GLOB license_files LIST_DIRECTORIES false "${license_glob}")
    if(NOT license_files)
      return()
    endif()

    jcm_follow_symlinks(PATHS "${license_files}" OUT_VAR followed_license_files)

    foreach(target_file original_file IN ZIP_LISTS followed_license_files license_files)
      cmake_path(GET original_file FILENAME original_file_name)

      if(target_file)
        install(
          FILES "${target_file}"
          DESTINATION "${JCM_INSTALL_DOC_DIR}/${dest_suffix}"
          RENAME "${original_file_name}")
      else()
        # only can be non-existent is if it was linked to, since glob was used
        string(REPLACE "-NOTFOUND" "" non_existent_file "${target_file}")
        message(WARNING "The license file in project ${PROJECT_NAME}, '${original_file}', points "
          "to a non-existent path: ${target_file}")
      endif()
    endforeach()
  endfunction()

  if(ARGS_INSTALL_LICENSES)
    cmake_path(GET JCM_PROJECT_LICENSES_DIR FILENAME licenses_dir)
    install_licenses("${PROJECT_SOURCE_DIR}/LICENSE*" "")
    install_licenses("${JCM_PROJECT_LICENSES_DIR}/*" "${licenses_dir}")
  endif()
endfunction()
