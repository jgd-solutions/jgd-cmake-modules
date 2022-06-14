include(JcmFileNaming)
include(JcmParseArguments)

macro(JCM_BASIC_PACKAGE_CONFIG project)
  # Include main targets file
  jcm_package_targets_file_name(PROJECT ${project} OUT_VAR target_file_name)
  if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/${target_file_name}")
    list(APPEND config_package_files "${target_file_name}")
    include("${CMAKE_CURRENT_LIST_DIR}/${target_file_name}")
  endif ()
  unset(target_file_name)

  # Include package components' config file
  foreach (component ${${project}_FIND_COMPONENTS})
    if(component STREQUAL project)
      continue()
    endif()

    jcm_package_config_file_name(PROJECT ${project} COMPONENT ${component} OUT_VAR component_file)
    list(APPEND config_package_files "${component_file}")
    include("${CMAKE_CURRENT_LIST_DIR}/${component_file}")
  endforeach ()
  unset(component_file)

  # Add config package's version file to collection of package modules
  jcm_package_version_file_name(PROJECT ${project} OUT_VAR version_file)
  if (EXISTS ${version_file})
    list(APPEND config_package_files ${version_file})
  endif ()
  unset(version_file)

  # Add config package's component target files to collection of package modules
  foreach (component ${${project}_FIND_COMPONENTS})
    jcm_package_targets_file_name(PROJECT ${project} COMPONENT ${component} OUT_VAR target_file)
    list(APPEND config_package_files ${target_file})
  endforeach ()
  unset(target_file)

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


# Expected to be in an appropriately named config file, included by a call to jcm_basic_package_config
macro(JCM_BASIC_COMPONENT_CONFIG project component)
  jcm_parse_arguments(MULTI_VALUE_KEYWORDS "REQUIRED_COMPONENTS" ARGUMENTS "${ARGN}")

  if (NOT TARGET ${project}::${component} AND NOT ${project}_BINARY_DIR)
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
