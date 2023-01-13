include_guard()

#[=======================================================================[.rst:

JcmConfigureFiles
-----------------

Use-case specific configure functions, like CMake's :cmake:command:`configure_file`
(`link <https://cmake.org/cmake/help/latest/command/configure_file.html>`_), but with features for
their respective use-case.

All input file names are simply the output file name with :cmake:variable:`JCM_IN_FILE_EXTENSION`
(.in) appended.

--------------------------------------------------------------------------

#]=======================================================================]

include(JcmParseArguments)
include(JcmFileNaming)
include(JcmCanonicalStructure)
include(CMakePackageConfigHelpers)

#[=======================================================================[.rst:

jcm_configure_package_config_file
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_configure_package_config_file

  .. code-block:: cmake

    jcm_configure_package_config_file(
      [TARGET <target> | COMPONENT <component>]
      [OUT_FILE_VAR <out-var>]
    )

Configures the package config-file for the project or for a project component when either
:cmake:variable:`TARGET` or :cmake:variable:`COMPONENT` is provided. The input and out config file
names and locations are internally determined from :cmake:command:`jcm_package_config_file_name`,
:cmake:variable:`JCM_PROJECT_CMAKE_DIR`, and :cmake:variable:`JCM_CMAKE_DESTINATION`.

Configuration occurs via CMake's :cmake:command:`configure_package_config_file`, such that the
configured files have access to the :cmake:variable:`PACKAGE_INIT` variable substitution.

Directly use this function to configure package config-files, or commission it from
:cmake:command:`jcm_install_config_file_package` with parameter
:cmake:variable:`CONFIGURE_PACKAGE_CONFIG_FILES`.

Parameters
##########

One Value
~~~~~~~~~

:cmake:variable:`TARGET`
  Target which the configured config-file represents. This target's `COMPONENT` property will be
  extracted to compute the appropriate config-file name. Prefer this if the target is available.

:cmake:variable:`COMPONENT`
  Project component which the configured config-file represents, used in conjunction with
  :cmake:variable:`PROJECT_NAME` to compute the appropriate config-file name. Use this if the
  respective target is unavailable.

:cmake:variable:`OUT_FILE_VAR`
  The named variable will be set to the absolute path of the output file.

Examples
########

.. code-block:: cmake

  # configure's project's top-level config-file using PROJECT_NAME

  jcm_configure_package_config_file()

.. code-block:: cmake

  # configure's libiceream::toppings's config-file

  jcm_configure_package_config_file(TARGET libicecream::toppings)

.. code-block:: cmake

  # same as above - PROJECT_NAME is libicecream

  jcm_configure_package_config_file(COMPONENT toppings)

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_configure_package_config_file)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "TARGET;COMPONENT;OUT_FILE_VAR"
    MUTUALLY_EXCLUSIVE "TARGET;COMPONENT"
    ARGUMENTS "${ARGN}")

  # use provided component or extract target's component property into an argument
  unset(comp_arg)
  unset(comp_err_msg)

  if(DEFINED ARGS_TARGET OR DEFINED ARGS_COMPONENT)
    if(DEFINED ARGS_COMPONENT)
      set(component ${ARGS_COMPONENT})
    else()
      get_target_property(component ${ARGS_TARGET} COMPONENT)
    endif()
    if(NOT component STREQUAL PROJECT_NAME)
      set(comp_arg COMPONENT ${component})
      set(comp_err_msg " for component ${component}")
    endif()
  endif()

  # resolve input and output pkg-config file names
  jcm_package_config_file_name(${comp_arg} OUT_VAR config_file)
  set(in_config_file "${config_file}${JCM_IN_FILE_EXTENSION}")
  string(PREPEND in_config_file "${JCM_PROJECT_CMAKE_DIR}/")
  string(PREPEND config_file "${JCM_CMAKE_DESTINATION}/")
  if(NOT EXISTS "${in_config_file}")
    message(
      FATAL_ERROR
      "Cannot configure a package config file for project "
      "${PROJECT_NAME}. Could not find file ${in_config_file}${comp_err_msg}.")
  endif()

  configure_package_config_file(
    "${in_config_file}"
    "${config_file}"
    INSTALL_DESTINATION "${JCM_INSTALL_CMAKE_DESTINATION}"
  )

  # output variable
  if(DEFINED ARGS_OUT_FILE_VAR)
    set(${ARGS_OUT_FILE_VAR} "${config_file}" PARENT_SCOPE)
  endif()
endfunction()

#[=======================================================================[.rst:

jcm_configure_file
^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_configure_file

  .. code-block:: cmake

    jcm_configure_file(
      IN_FILE <file>
      [OUT_FILE_VAR <out-var>]
    )

Configures the file specified by :cmake:variable:`IN_FILE`, just like CMake's
:cmake:command:`configure_file`, but follows JCM's input-file naming conventions, has richer error
checks and messages, and uses *@* uses substitution, only.

The output file will be computed by removing the file extension
:cmake:variable:`JCM_IN_FILE_EXTENSION` from :cmake:variable:`IN_FILE` and configuring the file to
:cmake:variable:`CMAKE_CURRENT_BINARY_DIR`, replacing `@` variables, only. Like
:cmake:command:`configure_file`, relative input paths are treated with respect to
:cmake:variable:`CMAKE_CURRENT_SOURCE_DIR`.

Use this function when configuring various files for which there is not a specific *configure*
function for, such as headers and sources.

Parameters
##########

One Value
~~~~~~~~~

:cmake:variable:`IN_FILE`
  The input config-file template.

:cmake:variable:`OUT_FILE_VAR`
  The variable named will be set to the output file path

Examples
########

.. code-block:: cmake

  jcm_configure_file(IN_FILE my_config.hpp.in)

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_configure_file)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "IN_FILE" "OUT_FILE_VAR"
    REQUIRES_ALL "IN_FILE"
    ARGUMENTS "${ARGN}"
  )

  cmake_path(GET ARGS_IN_FILE FILENAME in_file_name)
  jcm_transform_list(ABSOLUTE_PATH INPUT "${ARGS_IN_FILE}" OUT_VAR in_file_path)

  # Usage Guards
  # cmake's configure_file warns about directories being provided
  if(NOT in_file_name MATCHES "${JCM_IN_FILE_REGEX}")
    message(
      FATAL_ERROR
      "${ARGS_IN_FILE} does not end with the extension '${JCM_IN_FILE_EXTENSION}' required by "
      "${CMAKE_CURRENT_FUNCTION}")
  endif()

  if(NOT EXISTS "${in_file_path}")
    # configure_file warns about not existing, this is just more informative for specific project
    message(
      FATAL_ERROR
      "Cannot configure file '${in_file_path}' for project ${PROJECT_NAME}. "
      "The file does not exist")
  endif()

  # Configure
  string(REGEX REPLACE "${JCM_IN_FILE_REGEX}" "" out_file_name "${in_file_name}")
  configure_file("${in_file_path}" "${out_file_name}" @ONLY)

  # Out Var
  if(DEFINED ARGS_OUT_FILE_VAR)
    set(${ARGS_OUT_FILE_VAR} "${CMAKE_CURRENT_BINARY_DIR}/${out_file_name}" PARENT_SCOPE)
  endif()
endfunction()

#[=======================================================================[.rst:

jcm_configure_vcpkg_manifest_file
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_configure_vcpkg_manifest_file

  .. code-block:: cmake

    jcm_configure_vcpkg_manifest_file()

Configures an config template of a vcpkg manifest file located in
:cmake:variable:`JCM_PROJECT_CMAKE_DIR` to :cmake:variable:`PROJECT_SOURCE_DIR`, using `@`
substitution, only. This function provides consistency of configuring vcpkg manifests across
projects, and has no effect if the project is not the top-level project.

Examples
########

.. code-block:: cmake

  jcm_configure_vcpkg_manifest_file()

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_configure_vcpkg_manifest_file)
  if(NOT PROJECT_IS_TOP_LEVEL)
    return()
  endif()

  set(in_manifest_file "${JCM_PROJECT_CMAKE_DIR}/vcpkg.json${JCM_IN_FILE_EXTENSION}")

  if(NOT EXISTS "${in_manifest_file}")
    message(FATAL_ERROR "Cannot configure a vcpkg manifest file for project ${PROJECT_NAME}. "
      "Could not find file ${in_manifest_file}.")
  endif()

  configure_file("${in_manifest_file}" "${PROJECT_SOURCE_DIR}/vcpkg.json" @ONLY)
endfunction()
