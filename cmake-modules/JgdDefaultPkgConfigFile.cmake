@PACKAGE_INIT@

include(CMakeFindDependencyMacro)
find_dependency(cmake-modules CONFIG REQUIRED)

include(JgdFileNaming)

# Include main package config file
jgd_pkg_targets_file_name(PROJECT "@PROJECT_NAME@" OUT_VAR target_file_name)
include("${CMAKE_CURRENT_LIST_DIR}/${target_file_name}")
unset(target_file_name)

# Include package components' config file
foreach(component ${@PROJECT_NAME@_FIND_COMPONENTS})
  jgd_pkg_config_file_name(PROJECT "@PROJECT_NAME@" COMPONENT "${component}"
                           OUT_VAR comp_config_name)
  include("${CMAKE_CURRENT_LIST_DIR}/${comp_config_name}")
endforeach()
unset(comp_config_name)

# Append module path for additional CMake modules
file(
  GLOB_RECURSE module_files
  LIST_DIRECTORIES false
  "${JGD_CMAKE_MODULE_REGEX}")
if(module_files)
  list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")
endif()
unset(module_files)

# As recommended in CMake's configure_package_config_file command, ensure
# required components have been found
check_required_components(@PROJECT_NAME@)
