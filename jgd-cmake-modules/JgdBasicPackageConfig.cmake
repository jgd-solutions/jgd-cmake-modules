include(JgdFileNaming)
include(JgdParseArguments)

macro(JGD_BASIC_PACKAGE_CONFIG project)
  # Include main targets file
  jgd_package_targets_file_name(PROJECT ${project} OUT_VAR target_file_name)
  if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/${target_file_name}/${target_file_name}")
    list(APPEND config_package_files ${target_file_name})
    include("${CMAKE_CURRENT_LIST_DIR}/${target_file_name}")
  endif ()
  unset(target_file_name)

  # Include package components' config file
  foreach (component ${${project}_FIND_COMPONENTS})
    jgd_package_config_file_name(PROJECT ${project} COMPONENT ${component} OUT_VAR component_file)
    list(APPEND config_package_files ${component_file})
    include("${CMAKE_CURRENT_LIST_DIR}/${component_file}")
  endforeach ()
  unset(component_file)

  # Add config package's version file to collection of package modules
  jgd_package_version_file_name(PROJECT ${project} OUT_VAR version_file_name)
  if (EXISTS ${version_file_name})
    list(APPEND config_package_files ${version_file_name})
  endif ()
  unset(version_file_name)

  # Add config package's component target files to collection of package modules
  foreach (component ${${project}_FIND_COMPONENTS})
    jgd_package_targets_file_name(PROJECT ${project} COMPONENT ${component} OUT_VAR target_file)
    list(APPEND config_package_files ${target_file})
  endforeach ()
  unset(comp_target_name)

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
  check_required_components(${project})
endmacro()


# Expected to be in an appropriately named config file, included by a call to jgd_basic_package_config
macro(JGD_BASIC_COMPONENT_CONFIG project component)
  jgd_parse_arguments(MULTI_VALUE_KEYWORDS "REQUIRED_COMPONENTS" ARGUMENTS "${ARGN}")

  if (NOT TARGET ${project}::${component} AND NOT ${project}_BINARY_DIR)
    set(${project}_${component}_stored_req_components ${ARGS_REQUIRED_COMPONENTS})
    foreach (required_component ${ARGS_REQUIRED_COMPONENTS})
      jgd_package_config_file_name(PROJECT ${project} COMPONENT ${required_component} OUT_VAR config_file)
      include("${CMAKE_CURRENT_LIST_DIR}/${config_file}")
    endforeach ()
    unset(config_file)

    set(ARGS_REQUIRED_COMPONENTS ${${project}_${component}_stored_req_components})
    unset(${project}_${component}_stored_req_components)

    jgd_package_targets_file_name(PROJECT ${project} COMPONENT ${component} OUT_VAR targets_file)
    include("${CMAKE_CURRENT_LIST_DIR}/${targets_file}")
    unset(targets_file)
    set(${project}_${component}_FOUND TRUE)
  endif ()

  unset(ARGS_REQUIRED_COMPONENTS)
endmacro()