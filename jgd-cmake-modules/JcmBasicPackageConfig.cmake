#[=======================================================================[.rst:

JcmBasicPackageConfig
---------------------

Provides macros to create `Config-file Packages
<https://cmake.org/cmake/help/latest/manual/cmake-packages.7.html#config-file-packages>`_.  Offers
the :cmake:command:`jcm_basic_package_config` macro for top-level config-files, and the
:cmake:command:`jcm_basic_component_config` macro for config-files of individual components.

The utilities here follow a pattern of each target providing its on config-file and targets-file.
This makes managing inter-project dependencies very easy and simplifies overall logic.

--------------------------------------------------------------------------

#]=======================================================================]

include(JcmParseArguments)
include(JcmFileNaming)
include(JcmTargetNaming)

#[=======================================================================[.rst:

jcm_basic_package_config
^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_basic_package_config

  .. code-block:: cmake

    jcm_basic_package_config(<project>)


Provides all CMake commands that are required in a package config-files to create relocatable,
config-file packages. Call this macro at the *end* of your package config-file template
(<project>-config.cmake.in), after :code:`@PACKAGE_INIT@`.

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
  <https://cmake.org/cmake/help/latest/module/CMakePackageConfigHelpers.html#generating-a-package-configuration-file>`_
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
  resolve to the consuming project's name.

One Value
~~~~~~~~~

:cmake:variable:`NO_TARGETS`
  Indicates that this package does not provide any CMake targets at the top-level, causing this
  macro to skip inclusion of a targets file (<project>-targets.cmake). Consider a CMake library, for
  instance, or a library with components providing their own targets files.

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

--------------------------------------------------------------------------

#]=======================================================================]
macro(JCM_BASIC_PACKAGE_CONFIG project)
  jcm_parse_arguments(
    OPTIONS "NO_TARGETS"
    ARGUMENTS "${ARGN}"
  )

  # Include main targets file
  if (NOT ARGS_NO_TARGETS)
    jcm_package_targets_file_name(PROJECT ${project} OUT_VAR jcm_targets_file_name)
    list(APPEND jcm_config_package_files "${jcm_targets_file_name}")
    include("${CMAKE_CURRENT_LIST_DIR}/${jcm_targets_file_name}")
    unset(jcm_targets_file_name)
  endif ()
  unset(ARGS_NO_TARGETS)

  # Include package components' config file
  if(${project}_FIND_COMPONENTS)
    # include specified components
    foreach (jcm_find_component ${${project}_FIND_COMPONENTS})
      if(jcm_find_component STREQUAL project)
        continue()
      endif()

      jcm_package_config_file_name(
        PROJECT ${project}
        COMPONENT ${jcm_find_component}
        OUT_VAR jcm_component_config
      )
      if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/${jcm_component_config}")
        include("${CMAKE_CURRENT_LIST_DIR}/${jcm_component_config}")
        list(APPEND jcm_config_package_files "${jcm_component_config}")
      elseif(${project}_FIND_REQUIRED_${jcm_find_component})
        set(${project}_${jcm_find_component}_FOUND FALSE)
      endif()

      # add component's targets file to collection of package modules
      jcm_package_targets_file_name(
        PROJECT ${project}
        COMPONENT ${jcm_find_component}
        OUT_VAR jcm_component_targets
      )
      list(APPEND jcm_config_package_files "${jcm_component_targets}")
    endforeach ()

    unset(jcm_component_config)
    unset(jcm_component_targets)
  else()
    # include all components' config files
    file(
      GLOB
      jcm_components_configs
      LIST_DIRECTORIES false
      "${CMAKE_CURRENT_LIST_DIR}/*-config.cmake"
    )
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
    file(
      GLOB_RECURSE
      jcm_additional_modules
      LIST_DIRECTORIES false
      RELATIVE "${CMAKE_CURRENT_LIST_DIR}"
      "*.cmake"
    )
    list(REMOVE_ITEM jcm_additional_modules ${jcm_config_package_files})
    unset(jcm_config_package_files)

    if (jcm_additional_modules)
      list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")
    endif ()
  endif ()

  unset(jcm_current_dir_idx)
  unset(jcm_additional_modules)

  # As recommended in CMake's configure_package_config_file command, ensure
  # required components have been found
  check_required_components(${project})
endmacro()


#[=======================================================================[.rst:

jcm_basic_component_config
^^^^^^^^^^^^^^^^^^^^^^^^^^

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
- set the component's associated :cmake:variable:`<project>_<component>_FOUND` variables that
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

One Value
~~~~~~~~~

:cmake:variable:`NO_TARGETS`
  Indicates that this package does not provide any CMake targets, causing this macro to skip
  inclusion of a targets file (<project>-<component>-targets.cmake). The requirement for the
  presence of the expected target will also be skipped before setting
  :cmake:variable:`<project>_<component>_FOUND` to :cmake:`TRUE`.

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
  jcm_parse_arguments(
    OPTIONS "NO_TARGETS"
    MULTI_VALUE_KEYWORDS "REQUIRED_COMPONENTS"
    ARGUMENTS "${ARGN}"
  )

  if (NOT ${project}_${component}_FOUND)
    # store arguments in case included config file overwrites it
    set(${project}_${component}_stored_req_components ${ARGS_REQUIRED_COMPONENTS})
    set(${project}_${component}_stored_no_targets ${ARGS_NO_TARGETS})

    # include required components' config files
    foreach (jcm_required_component ${ARGS_REQUIRED_COMPONENTS})
      jcm_package_config_file_name(
        PROJECT ${project}
        COMPONENT ${jcm_required_component}
        OUT_VAR jcm_required_component_config_file
      )
      include("${CMAKE_CURRENT_LIST_DIR}/${jcm_required_component_config_file}")
    endforeach ()
    unset(jcm_required_component_config_file)

    # restore arguments
    set(ARGS_REQUIRED_COMPONENTS ${${project}_${component}_stored_req_components})
    set(ARGS_NO_TARGETS ${${project}_${component}_stored_no_targets})
    unset(${project}_${component}_stored_req_components)
    unset(${project}_${component}_stored_no_targets)

    if(NOT ARGS_NO_TARGETS)
      # include associated targets file
      jcm_package_targets_file_name(
        PROJECT ${project}
        COMPONENT ${component}
        OUT_VAR jcm_component_targets
      )
      include("${CMAKE_CURRENT_LIST_DIR}/${jcm_component_targets}")
      unset(jcm_component_targets)

      # check for presence of expected target
      jcm_executable_naming(
        PROJECT ${project}
        COMPONENT ${component}
        OUT_EXPORT_NAME jcm_executable_component_export_name
      )
      jcm_library_naming(
        PROJECT ${project}
        COMPONENT ${component}
        OUT_EXPORT_NAME jcm_library_component_export_name
      )

      if(TARGET ${project}::${jcm_executable_component_export_name} OR
         TARGET ${project}::${jcm_library_component_export_name})
        set(${project}_${component}_FOUND TRUE)
      else()
        set(${project}_${component}_FOUND FALSE)
      endif()

    else()
      set(${project}_${component}_FOUND TRUE)
    endif()

  endif ()

  unset(ARGS_REQUIRED_COMPONENTS)
  unset(ARGS_NO_TARGETS)
endmacro()
