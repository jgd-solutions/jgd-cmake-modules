include_guard()

include(JcmParseArguments)
include(JcmFileNaming)
include(CMakePackageConfigHelpers)

# without target -> for the project with target -> specifically for the target
function(jcm_configure_package_config_file)
  jcm_parse_arguments(ONE_VALUE_KEYWORDS "TARGET;COMPONENT"
    MUTUALLY_EXCLUSIVE "TARGET;COMPONENT" ARGUMENTS "${ARGN}")

  # use provided component or extract target's component property into an argument
  if (DEFINED ARGS_TARGET OR DEFINED ARGS_COMPONENT)
    if (DEFINED ARGS_COMPONENT)
      set(component ${ARGS_COMPONENT})
    else ()
      get_target_property(component ${target} COMPONENT)
    endif ()
    if (NOT component STREQUAL PROJECT_NAME)
      set(comp_arg COMPONENT ${component})
      set(comp_err_msg " for component ${component}")
    endif ()
  endif ()

  # resolve input and output pkg-config file names
  jcm_package_config_file_name(${comp_arg} OUT_VAR config_file)
  set(in_config_file "${config_file}${JCM_IN_FILE_EXTENSION}")
  string(PREPEND in_config_file "${JCM_PROJECT_CMAKE_DIR}/")
  string(PREPEND config_file "${JCM_CMAKE_DESTINATION}/")
  if (NOT EXISTS "${in_config_file}")
    message(
      FATAL_ERROR
      "Cannot configure a package config file for project "
      "${PROJECT_NAME}. Could not find file ${in_config_file}${comp_err_msg}."
    )
  endif ()

  configure_package_config_file(
    "${in_config_file}" "${config_file}"
    INSTALL_DESTINATION "${JCM_INSTALL_CMAKE_DESTINATION}")
endfunction()

# without target -> for the project (common) with target -> specifically for the
# target
function(jcm_configure_config_header_file)
  jcm_parse_arguments(ONE_VALUE_KEYWORDS "TARGET" ARGUMENTS "${ARGN}")

  # extract target's component property into an argument
  set(comp_arg)
  set(comp_err_msg)
  if (DEFINED ARGS_TARGET)
    get_target_property(component ${target} COMPONENT)
    if (component AND NOT component STREQUAL PROJECT_NAME)
      set(comp_arg COMPONENT ${component})
      set(comp_err_msg " for component ${component}")
    endif ()
  endif ()

  jcm_config_header_file_name(${comp_arg} OUT_VAR header_file)
  set(in_header_file "${header_file}${JCM_IN_FILE_EXTENSION}")
  string(PREPEND in_header_file "${JCM_PROJECT_CMAKE_DIR}/")
  string(PREPEND header_file "${JCM_HEADER_DESTINATION}/")
  if (NOT EXISTS "${in_header_file}")
    message(
      FATAL_ERROR
      "Cannot configure a configuration header for project "
      "${PROJECT_NAME}. Could not find file ${in_header_file}${comp_err_msg}."
    )
  endif ()

  configure_file("${in_header_file}" "${header_file}" @ONLY)
endfunction()

function(jcm_configure_vcpkg_manifest_file)
  if(NOT PROJECT_IS_TOP_LEVEL)
    return()
  endif()

  set(manifest_file "${JCM_PROJECT_CMAKE_DIR}/vcpkg.json")
  set(in_manifest_file "${manifest_file}${JCM_IN_FILE_EXTENSTION}")

  if (NOT EXISTS "${in_manifest_file}")
    message(FATAL_ERROR "Cannot configure a vcpkg manifest file for project ${PROJECT_NAME}. "
      "Could not find file ${in_manifest_file}.")
  endif ()

  configure_file("${in_manifest_file}" "${manifest_file}" @ONLY)
endfunction()
