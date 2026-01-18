if(CMAKE_EXPERIMENTAL_EXPORT_PACKAGE_INFO)
  set(spdx_license_arg SPDX_LICENSE BSD-3-Clause)
endif()

cmake_minimum_required(VERSION 3.25)
project(
  jgd-cmake-modules
  VERSION 3.15.1
  ${spdx_license_arg}
  DESCRIPTION "CMake library for standardized CMake projects for JGD"
  HOMEPAGE_URL "https://jgd-solutions.github.io/jgd-cmake-modules/"
  LANGUAGES C) # GnuInstallDirs requires system arch, most reliably resolved by enabling a compiled lang

# must amend module path, as we can't find_package on ourself
list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}")
list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}/find-modules")

include(JcmSetupProject)
include(JcmStandardDirs)
include(JcmInstallConfigFilePackage)
include(JcmConfigureFiles)

jcm_setup_project(PREFIX_NAME "JCM")
jcm_configure_vcpkg_manifest_file()

jcm_add_option(
  NAME JCM_INSTALL_LICENSES
  DESCRIPTION "Triggers the installation to install license files"
  TYPE BOOL
  DEFAULT ON)

if(JCM_ENABLE_TESTS)
  # Preemptively finding ClangFormat to see what ClangFormat the test projects will use
  find_package(ClangFormat)
  add_subdirectory("${JCM_PROJECT_TESTS_DIR}")
endif()

if(JCM_ENABLE_DOCS)
  find_package(Sphinx REQUIRED)
  add_subdirectory("${JCM_PROJECT_DOCS_DIR}")
endif()

if(JCM_INSTALL_LICENSES)
  set(install_licences_arg "INSTALL_LICENSES")
else()
  unset(install_licences_arg)
endif()

jcm_install_config_file_package(
  ${install_licences_arg}
  CONFIGURE_PACKAGE_CONFIG_FILES
  CMAKE_MODULES "${PROJECT_NAME}")
