include(JgdFileNaming)
include(JgdParseArguments)

macro(JGD_BASIC_PACKAGE_CONFIG)
  jgd_parse_arguments(
    ONE_VALUE_KEYWORDS "PROJECT"
    REQUIRES_ALL "PROJECT"
    ARGUMENTS "${ARGN}")

  # Include main targets file
  jgd_package_targets_file_name(PROJECT ${ARGS_PROJECT} OUT_VAR target_file_name)
  if (EXISTS ${target_file_name})
    list(APPEND config_package_files ${target_file_name})
    include(${target_file_name})
  endif ()
  unset(target_file_name)

  # Include package components' config file
  foreach (component ${${ARGS_PROJECT}_FIND_COMPONENTS})
    jgd_package_config_file_name(PROJECT ${ARGS_PROJECT} COMPONENT ${component}
      OUT_VAR comp_config_name)
    set_and_check(comp_config_name ${comp_config_name})
    list(APPEND config_package_files ${comp_config_name})
    include(${comp_config_name})
  endforeach ()
  unset(comp_config_name)

  # Add config package's version file to collection of package modules
  jgd_package_version_file_name(PROJECT ${ARGS_PROJECT} OUT_VAR version_file_name)
  if (EXISTS ${version_file_name})
    list(APPEND config_package_files ${version_file_name})
  endif ()
  unset(version_file_name)

  # Append module path for any additional (non-package) CMake modules
  list(FIND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}" idx)
  if (idx EQUAL -1)
    file(GLOB_RECURSE additional_modules
      LIST_DIRECTORIES false
      RELATIVE "${CMAKE_CURRENT_LIST_DIR}" "*.cmake")
    list(REMOVE_ITEM additional_modules ${config_package_files})
    unset(config_package_files)

    if (additional_modules)
      list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")
    endif ()
    unset(additional_modules)
  endif ()
  unset(idx)

  # As recommended in CMake's configure_package_config_file command, ensure
  # required components have been found
  check_required_components(${ARGS_PROJECT})
endmacro()

