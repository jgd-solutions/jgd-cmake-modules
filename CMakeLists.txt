cmake_minimum_required(VERSION 3.23)
project(
  jgd-cmake-modules
  VERSION 0.6.0
  DESCRIPTION "CMake library for standardized CMake projects at JGD"
  HOMEPAGE_URL "https://gitlab.com/jgd-solutions/cmake-modules"
  LANGUAGES NONE)

list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/jgd-cmake-modules")
include(JgdSetupProject)
include(JgdStandardDirs)
include(JgdInstallConfigFilePackage)

jgd_setup_project(PREFIX_NAME "CMM")

if(CMM_BUILD_TESTS)
  add_subdirectory("${JGD_PROJECT_TESTS_DIR}")
endif()

jgd_install_config_file_package(
  CONFIGURE_PACKAGE_CONFIG_FILES
  CMAKE_MODULES "jgd-cmake-modules")

configure_file("${JGD_PROJECT_CMAKE_DIR}/vcpkg.json.in" "${PROJECT_SOURCE_DIR}/vcpkg.json" @ONLY)
