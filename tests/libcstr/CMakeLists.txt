cmake_minimum_required(VERSION 3.20)
project(libcstr VERSION 0.0.0 LANGUAGES C)

find_package(jgd-cmake-modules CONFIG REQUIRED)
find_package(ClangFormat)

include(JcmAllModules)
jcm_setup_project()
jcm_source_subdirectories(ADD_SUBDIRS WITH_TESTS_DIR)
jcm_install_config_file_package(
  INSTALL_LICENSES
  CONFIGURE_PACKAGE_CONFIG_FILES TARGETS libcstr::libcstr)
jcm_create_clang_format_targets(SOURCE_TARGETS libcstr::libcstr)
