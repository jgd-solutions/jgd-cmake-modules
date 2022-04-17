cmake_minimum_required(VERSION 3.20)
project(
  cmake-modules
  LANGUAGES NONE
  VERSION 0.0.0)

list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake-modules")
include(JgdSetupProject)
include(JgdSourceSubdirectories)
include(JgdInstallConfigFilePkg)
include(JgdStandardDirs)

jgd_setup_project(PREFIX_NAME "CMM")
jgd_source_subdirectories(ADD_SUBDIRS)
add_subdirectory(${JGD_PROJECT_TESTS_DIR})
# jgd_install_config_file_pkg(CMAKE_MODULES "cmake-modules")
