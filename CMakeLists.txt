cmake_minimum_required(VERSION 3.20)
project(
  cmake-modules
  LANGUAGES NONE
  VERSION 0.0.0)

list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake-modules")
include(JgdSetupProject)
include(JgdSourceSubdirectories)
include(JgdStandardDirs)
include(JgdInstallConfigFilePackage)

jgd_setup_project(PREFIX_NAME "CMM")
add_subdirectory("${JGD_PROJECT_TESTS_DIR}")
jgd_install_config_file_package(CONFIGURE_PACKAGE_CONFIG_FILES CMAKE_MODULES "cmake-modules")
