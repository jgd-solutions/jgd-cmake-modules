cmake_minimum_required(VERSION 3.23)
project(
  jgd-cmake-modules
  VERSION 2.3.2
  DESCRIPTION "CMake library for standardized CMake projects for JGD"
  HOMEPAGE_URL "https://gitlab.com/jgd-solutions/jgd-cmake-modules"
  LANGUAGES NONE)

set(CMAKE_INSTALL_LIBDIR "lib") # not used - set to calm GNUInstallDirs

# must amend module path, as we can't find_package on ourself
list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}")
list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}/find-modules")

include(JcmSetupProject)
include(JcmStandardDirs)
include(JcmInstallConfigFilePackage)
include(JcmConfigureFiles)

jcm_setup_project(PREFIX_NAME "JCM")

if (JCM_BUILD_TESTS)
  # Unnecessarily finding ClangFormat here to see what ClangFormat test projects will use
  find_package(ClangFormat)
  add_subdirectory("${JCM_PROJECT_TESTS_DIR}")
endif ()

if (JCM_BUILD_DOCS)
  find_package(Sphinx REQUIRED)
  add_subdirectory("${JCM_PROJECT_DOCS_DIR}")
endif ()

jcm_install_config_file_package(
  INSTALL_LICENSES
  CONFIGURE_PACKAGE_CONFIG_FILES
  CMAKE_MODULES "${PROJECT_NAME}")

jcm_configure_vcpkg_manifest_file()
