cmake_minimum_required(VERSION 3.20)
project(cmake-modules LANGUAGES NONE)

list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake-modules")
include(JgdSetupProject)
include(JgdInstallConfigFilePkg)

jgd_setup_project(CONFIGURE_PKG_CONFIG_FILES WITH_TESTS)
jgd_install_config_file_pkg(CMAKE_MODULES "cmake-modules")
