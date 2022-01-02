cmake_minimum_required(VERSION 3.17)
project(cmake-modules LANGUAGES NONE)

list(PREPEND CMAKE_MODULE_PATH "cmake-modules")
include(JgdSetupDefaultProject)
include(JgdInstallTargets)
include(JgdAddDefaultLibrary)

jgd_setup_default_project(CONFIGURE_PKG_CONFIG_FILES WITH_TESTS)
jgd_add_default_library(LIBRARY "${PROJECT_NAME}" TYPE "INTERFACE")
jgd_install_targets(TARGETS ${PROJECT_NAME} CMAKE_MODULES "cmake-modules")
