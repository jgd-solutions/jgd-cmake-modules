cmake_minimum_required(VERSION 3.20)
project(libcomponents VERSION 0.0.0 LANGUAGES CXX)

find_package(jgd-cmake-modules CONFIG REQUIRED)
include(JcmAllModules)

jcm_setup_project()
jcm_source_subdirectories(ADD_SUBDIRS WITH_TESTS_DIR LIB_COMPONENTS core extra)
jcm_configure_config_header_file()
jcm_install_config_file_package(CONFIGURE_PACKAGE_CONFIG_FILES
  TARGETS libcomponents::core libcomponents::extra)
jcm_create_clang_format_targets(VERBOSE EXCLUDE_REGEX "libcomponents_config.hpp$"
  TARGETS libcomponents::core libcomponents::extra)
