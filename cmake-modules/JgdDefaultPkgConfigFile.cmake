@PACKAGE_INIT@

include(CMakeFindDependencyMacro)
find_dependency(cmake-modules CONFIG REQUIRED)

include(JgdFileNaming)
jgd_pkg_targets_file_name(PROJECT "@PROJECT_NAME@" OUT_VAR target_file)
jgd_pkg_version_file_name(PROJECT "@PROJECT_NAME@" OUT_VAR version_file)
include("${CMAKE_CURRENT_LIST_DIR}/${target_file_name}")

unset(target_file_name)

file(GLOB <variable> "" [<globbing-expressions>...])
if()
  list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")
endif()

check_required_components(@PROJECT_NAME@)
