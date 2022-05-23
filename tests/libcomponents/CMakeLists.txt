cmake_minimum_required(VERSION 3.20)
project(libcomponents VERSION 0.0.0 LANGUAGES CXX)

find_package(jgd-cmake-modules CONFIG REQUIRED)
include(JgdAllModules)

jgd_setup_project()
jgd_source_subdirectories(ADD_SUBDIRS WITH_TESTS_DIR LIB_COMPONENTS core extra)
jgd_configure_config_header_file()
jgd_install_config_file_package(CONFIGURE_PACKAGE_CONFIG_FILES
  TARGETS libcomponents::core libcomponents::extra)
jgd_create_clang_format_targets(VERBOSE EXCLUDE_REGEX "libcomponents_config.hpp$"
  TARGETS libcomponents::core libcomponents::extra)
