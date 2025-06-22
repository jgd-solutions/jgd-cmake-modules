cmake_minimum_required(VERSION 3.23)
project(many-exec VERSION 0.0.0 LANGUAGES CXX)

find_package(jgd-cmake-modules CONFIG REQUIRED)
if(PROJECT_IS_TOP_LEVEL)
  find_package(ClangFormat)
endif()

include(JcmAllModules)
jcm_setup_project()

# a very large project may want to omit expensive configuration of a component
include(manyExecBuildTargetOptions)
many_exec_get_enabled_targets(
  OUT_BUILD_TARGETS  "MANY_EXEC_ENABLE_TARGETS"
  OUT_FORMAT_TARGETS "MANY_EXEC_CLANG_FORMAT_TARGETS")

message(WARNING "CMAKE_CXX_STANDARD: ${CMAKE_CXX_STANDARD}")

jcm_source_subdirectories(ADD_SUBDIRS WITH_TESTS_DIR)

jcm_install_config_file_package(
  CONFIGURE_PACKAGE_CONFIG_FILES
  TARGETS ${MANY_EXEC_ENABLE_TARGETS})

jcm_create_clang_format_targets(
  SOURCE_TARGETS ${MANY_EXEC_CLANG_FORMAT_TARGETS})
