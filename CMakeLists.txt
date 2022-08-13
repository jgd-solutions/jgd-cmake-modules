cmake_minimum_required(VERSION 3.23)
project(
  jgd-cmake-modules
  VERSION 0.9.4
  DESCRIPTION "CMake library for standardized CMake projects for JGD"
  HOMEPAGE_URL "https://gitlab.com/jgd-solutions/jgd-cmake-modules"
  LANGUAGES NONE)

list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/jgd-cmake-modules")
include(JcmSetupProject)
include(JcmStandardDirs)
include(JcmInstallConfigFilePackage)
include(JcmConfigureFiles)

jcm_setup_project(PREFIX_NAME "JCM")

if(JCM_BUILD_TESTS)
  add_subdirectory("${JCM_PROJECT_TESTS_DIR}")
endif()

jcm_install_config_file_package(
  CONFIGURE_PACKAGE_CONFIG_FILES
  CMAKE_MODULES "jgd-cmake-modules"
)
jcm_configure_vcpkg_manifest_file()
