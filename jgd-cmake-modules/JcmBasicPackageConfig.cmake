#[=======================================================================[.rst:

JcmBasicPackageConfig
---------------------

Provides macros to create `Config-file Packages
<https://cmake.org/cmake/help/latest/manual/cmake-packages.7.html#config-file-packages>`.  Offers
the :cmake:command:`jcm_basic_package_config` macro for top-level config-files, and the
:cmake:command:`jcm_basic_component_config` macro for config-files of individual components.

#]=======================================================================]

include(JcmFileNaming)
include(JcmParseArguments)

#[=======================================================================[.rst:
.. cmake:command:: jcm_basic_package_config

  .. code-block:: cmake

    jcm_basic_package_config(<project>)


Provides all CMake commands that are required in a package config-files to create relocatable,
config-file packages. Call this macro at the *end* of your package config-file template
(<project>-config.cmake.in), after :cmake:`@PACKAGE_INIT@`.

This macro will:

- include the associated targets file from the current list directory, if it exists
- include the components's config files and targets files for the components requested by the
  consumer's :cmake:command:`find_package` call, or all of those installed, if no components are
  explicitly requested. Requested components of `${project}` are ignored.
- if any CMake modules not corresponding to config-file packages (config files, targets files,
  version files...) exist in :cmake:variable:`CMAKE_CURRENT_LIST_DIR`, the directory will be
  appended to :cmake:variable:`CMAKE_MODULE_PATH` so consumers have access to these additional
  modules.
- call :cmake:command:`check_required_components`, as `KitWare recommends
  <https://cmake.org/cmake/help/latest/module/CMakePackageConfigHelpers.html#generating-a-package-configuration-file>`
  at the end of every package config-file. To get this macro in :cmake:variable:`PACKAGE_INIT`,
  ensure your config-file template is configured through
  :cmake:command:`configure_package_config_file`, or preferrably enable configuring in
  :cmake:command:`jcm_install_config_file_package`.

Parameters
##########

Positional
~~~~~~~~~~

:cmake:variable:`project`
  The name of the project being packaged. Don't use :cmake:`${PROJECT_NAME}`, as this will
  resolve to the consuming project name.

Examples
########

Most package config files will take this form.

.. code-block:: none
  :caption: libvideo-config.cmake.in

  @PACKAGE_INIT@

  include(CMakeFindDependencyMacro)
  find_dependency(jgd-cmake-modules CONFIG REQUIRED)

  include(JcmBasicPackageConfig)
  jcm_basic_package_config(@PROJECT_NAME@)

#]=======================================================================]
macro(JCM_BASIC_PACKAGE_CONFIG project)
  # Include main targets file
  jcm_package_targets_file_name(PROJECT ${project} OUT_VAR jcm_target_file_name)
  if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/${jcm_target_file_name}")
    list(APPEND jcm_config_package_files "${jcm_target_file_name}")
    include("${CMAKE_CURRENT_LIST_DIR}/${jcm_target_file_name}")
  endif ()
  unset(jcm_target_file_name)

  # Include package components' config file
  if(${project}_FIND_COMPONENTS)
    # include specified components
    foreach (component ${${project}_FIND_COMPONENTS})
      if(component STREQUAL project)
        continue()
      endif()

      jcm_package_config_file_name(
        PROJECT ${project}
        COMPONENT ${component}
        OUT_VAR jcm_component_config
      )
      include("${CMAKE_CURRENT_LIST_DIR}/${jcm_component_config}")

      # add component's config and targets file to collection of package modules
      jcm_package_targets_file_name(
        PROJECT ${project}
        COMPONENT ${component}
        OUT_VAR jcm_component_targets
      )
      list(APPEND jcm_config_package_files "${jcm_component_config}" "${jcm_component_targets}")
    endforeach ()

    unset(jcm_component_config)
    unset(jcm_component_targets)
  else()
    # include all components' config files
    file(GLOB jcm_components_configs LIST_DIRECTORIES false "${CMAKE_CURRENT_LIST_DIR}/*-config.cmake")
    list(REMOVE_ITEM jcm_components_configs "${CMAKE_CURRENT_LIST_FILE}")

    foreach (jcm_component_config IN LISTS jcm_components_configs)
      include("${jcm_component_config}")
    endforeach ()

    # add component's config and targets file to collection of package modules
    set(jcm_components_targets "${jcm_components_configs}")
    list(TRANSFORM jcm_components_targets REPLACE "-config.cmake$" "-targets.cmake")
    list(APPEND jcm_config_package_files "${jcm_components_configs}" "${jcm_components_targets}")

    unset(jcm_components_configs)
    unset(jcm_components_targets)
  endif()

  # Add config package's version file to collection of package modules
  jcm_package_version_file_name(PROJECT ${project} OUT_VAR jcm_version_file)
  if (EXISTS ${jcm_version_file})
    list(APPEND jcm_config_package_files ${jcm_version_file})
  endif ()
  unset(jcm_version_file)

  # Append module path for any additional (non-package) CMake modules
  list(FIND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}" jcm_current_dir_idx)
  if (jcm_current_dir_idx EQUAL -1)
    file(GLOB_RECURSE jcm_additional_modules
      LIST_DIRECTORIES false
      RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "*.cmake")
    list(REMOVE_ITEM jcm_additional_modules ${jcm_config_package_files})
    unset(jcm_config_package_files)

    if (jcm_additional_modules)
      list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")
    endif ()
    unset(jcm_additional_modules)
  endif ()
  unset(jcm_current_dir_idx)

  # As recommended in CMake's configure_package_config_file command, ensure
  # required components have been found
  check_required_components(${project})
endmacro()


#[=======================================================================[.rst:
.. cmake:command:: jcm_basic_component_config

  .. code-block:: cmake

    jcm_basic_component_config(<project> <component>
      [REQUIRED_COMPONENTS <component>...]
    )


Provides all CMake commands that are required in a package config-files of individual project
components. This macro is expected to be in a file

This macro will:

- include the config-files of any dependent components
- include the associated targets file from the current list directory
- set the component's associated `<project>_<component>_FOUND` variables that
  :cmake:command:`check_required_components` uses.

Parameters
##########

Positional
~~~~~~~~~~

:cmake:variable:`project`
  The name of the project being packaged. Don't use :cmake:`${PROJECT_NAME}`, as this will
  resolve to the consuming project name.

:cmake:variable:`component`
  The name of the component provided by this config-file.

Multi Value
~~~~~~~~~~~

:cmake:variable:`REQUIRED_COMPONENTS`
  Other components of the same project that this component depends upon.

Examples
########

Most package config files will take this form. Examples represent the components' config-files for a
fantasy project, *libvideo*, offering components *core*, *compression*, *stream*, and *freemium*.

.. code-block:: none
  :caption: libvideo-core-config.cmake.in

  jcm_basic_component_config(@PROJECT_NAME@ core)

.. code-block:: none
  :caption: libvideo-compression-config.cmake.in

  jcm_basic_component_config(@PROJECT_NAME@ compression REQUIRED_COMPONENTS core)

.. code-block:: none
  :caption: libvideo-stream-config.cmake.in

  jcm_basic_component_config(@PROJECT_NAME@ stream REQUIRED_COMPONENTS core compression)

.. code-block:: none
  :caption: libvideo-freemium-config.cmake.in

  jcm_basic_component_config(@PROJECT_NAME@ freemium REQUIRED_COMPONENTS core)

#]=======================================================================]
macro(JCM_BASIC_COMPONENT_CONFIG project component)
  jcm_parse_arguments(MULTI_VALUE_KEYWORDS "REQUIRED_COMPONENTS" ARGUMENTS "${ARGN}")

  if (NOT TARGET ${project}::${component})
    # store argument in case included config file overwrites it
    set(${project}_${component}_stored_req_components ${ARGS_REQUIRED_COMPONENTS})

    foreach (required_component ${ARGS_REQUIRED_COMPONENTS})
      jcm_package_config_file_name(PROJECT ${project} COMPONENT ${required_component} OUT_VAR config_file)
      include("${CMAKE_CURRENT_LIST_DIR}/${config_file}")
    endforeach ()
    unset(config_file)

    # restore argument
    set(ARGS_REQUIRED_COMPONENTS ${${project}_${component}_stored_req_components})
    unset(${project}_${component}_stored_req_components)

    jcm_package_targets_file_name(PROJECT ${project} COMPONENT ${component} OUT_VAR targets_file)
    include("${CMAKE_CURRENT_LIST_DIR}/${targets_file}")
    unset(targets_file)

    if(TARGET ${project}::${component})
      set(${project}_${component}_FOUND TRUE)
    else()
      set(${project}_${component}_FOUND FALSE)
    endif()
  endif ()

  unset(ARGS_REQUIRED_COMPONENTS)
endmacro()
