cmake_minimum_required(VERSION 3.20)
project(cmake-modules LANGUAGES NONE)

list(PREPEND CMAKE_MODULE_PATH "cmake-modules")
include(JgdSetupDefaultProject)
include(JgdInstallPackage)
include(JgdAddDefaultLibrary)

jgd_setup_default_project(CONFIGURE_PKG_CONFIG_FILES WITH_TESTS)
jgd_add_default_library(LIBRARY "${PROJECT_NAME}" TYPE "INTERFACE")
jgd_install_package(TARGETS ${PROJECT_NAME} CMAKE_MODULES "cmake-modules")

# Install cmake-modules so test projects can consume cmake-modules with the
# find_package() pattern that real consumers would
add_custom_command(
  TARGET test
  PRE_BUILD
  COMMAND "${CMAKE_COMMAND}" --install "${PROJECT_BINARY_DIR}" --prefix
          "${CMAKE_CURRENT_BINARY_DIR}/tests/install-for-tests"
  VERBATIM)
