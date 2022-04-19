include_guard()

include(JgdParseArguments)
include(JgdFileNaming)
include(CMakePackageConfigHelpers)

# without target -> for the project with target -> specifically for the target
function(jgd_configure_package_config_file)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "TARGET" ARGUMENTS "${ARGN}")

  # extract target's component property into an argument
  if (DEFINED ARGS_TARGET)
    get_target_property(component ${target} COMPONENT)
    if (component AND NOT component STREQUAL PROJECT_NAME)
      set(comp_arg COMPONENT ${component})
      set(comp_err_msg " for component ${component}")
    endif ()
  endif ()

  # resolve input and output pkg-config file names
  jgd_package_config_file_name(${comp_arg} OUT_VAR config_file)
  set(in_config_file "${config_file}${JGD_IN_FILE_EXTENSION}")
  string(PREPEND in_config_file "${JGD_PROJECT_CMAKE_DIR}/")
  string(PREPEND config_file "${JGD_CMAKE_DESTINATION}/")
  if (NOT EXISTS "${in_config_file}")
    message(
      FATAL_ERROR
      "Cannot configure a package config file for project "
      "${PROJECT_NAME}. Could not find file ${in_config_file}${comp_err_msg}."
    )
  endif ()

  configure_package_config_file(
    "${in_config_file}" "${config_file}"
    INSTALL_DESTINATION "${JGD_INSTALL_CMAKE_DESTINATION}")
endfunction()

# without target -> for the project (common) with target -> specifically for the
# target
function(jgd_configure_config_header_file)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "TARGET" ARGUMENTS "${ARGN}")

  # extract target's component property into an argument
  if (DEFINED ARGS_TARGET)
    get_target_property(component ${target} COMPONENT)
    if (component AND NOT component STREQUAL PROJECT_NAME)
      set(comp_arg COMPONENT ${component})
      set(comp_err_msg " for component ${component}")
    endif ()
  endif ()

  jgd_config_header_file_name(${comp_arg} OUT_VAR header_file)
  set(in_header_file "${header_file}${JGD_IN_FILE_EXTENSION}")
  string(PREPEND in_header_file "${JGD_PROJECT_CMAKE_DIR}/")
  string(PREPEND header_file "${JGD_HEADER_DESTINATION}/")
  if (NOT EXISTS "${in_header_file}")
    message(
      FATAL_ERROR
      "Cannot configure a configuration header for project "
      "${PROJECT_NAME}. Could not find file ${in_header_file}${comp_err_msg}."
    )
  endif ()

  configure_file("${in_header_file}" "${header_file}" @ONLY)
endfunction()

