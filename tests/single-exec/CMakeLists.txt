cmake_minimum_required(VERSION 3.20)
project(single-exec VERSION 0.0.0 LANGUAGES CXX)

find_package(jgd-cmake-modules CONFIG REQUIRED)
find_package(ClangFormat)
include(JcmAllModules)


jcm_setup_project()
message(STATUS "STANDARD ${CMAKE_CXX_STANDARD}")
jcm_source_subdirectories(ADD_SUBDIRS WITH_TESTS_DIR)

jcm_install_config_file_package(
  CONFIGURE_PACKAGE_CONFIG_FILES
  TARGETS single-exec::single-exec
)
jcm_create_clang_format_targets(
  SOURCE_TARGETS
    single-exec::single-exec
    single-exec_single-exec-library
)
