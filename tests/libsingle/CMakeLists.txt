cmake_minimum_required(VERSION 3.24)
project(libsingle VERSION 0.0.0 LANGUAGES CXX)

find_package(jgd-cmake-modules CONFIG REQUIRED)
if(PROJECT_IS_TOP_LEVEL)
  find_package(ClangFormat)
endif()
if(LIBSINGLE_ENABLE_DOCS)
  find_package(Doxygen REQUIRED COMPONENTS doxygen)
endif()

include(JcmAllModules)
jcm_setup_project()

jcm_source_subdirectories(
  ADD_SUBDIRS
  WITH_TESTS_DIR
  WITH_DOCS_DIR)

jcm_create_clang_format_targets(
  SOURCE_TARGETS libsingle::libsingle)

jcm_install_config_file_package(
  INSTALL_LICENSES
  CONFIGURE_PACKAGE_CONFIG_FILES
  TARGETS libsingle::libsingle)
