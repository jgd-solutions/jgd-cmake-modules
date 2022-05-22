cmake_minimum_required(VERSION 3.20)
project(
  jgd-cmake-modules
  VERSION 0.5.0
  DESCRIPTION "CMake library for standardized CMake projects at JGD"
  HOMEPAGE_URL "https://gitlab.com/jgd-solutions/cmake-modules"
  LANGUAGES NONE)

list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/jgd-cmake-modules")
include(JgdSetupProject)
include(JgdSourceSubdirectories)
include(JgdStandardDirs)
include(JgdInstallConfigFilePackage)

jgd_setup_project(PREFIX_NAME "CMM")
add_subdirectory("${JGD_PROJECT_TESTS_DIR}")
jgd_install_config_file_package(
  CONFIGURE_PACKAGE_CONFIG_FILES
  CMAKE_MODULES "jgd-cmake-modules")

configure_file("${JGD_PROJECT_CMAKE_DIR}/vcpkg.json.in" "${PROJECT_SOURCE_DIR}/vcpkg.json" @ONLY)
