cmake_minimum_required(VERSION 3.23)
project(libheaders VERSION 0.0.0 LANGUAGES CXX)

find_package(jgd-cmake-modules CONFIG REQUIRED)
include(JcmAllModules)

jcm_setup_project()
jcm_source_subdirectories(ADD_SUBDIRS WITH_TESTS_DIR)
jcm_configure_config_header_file()
jcm_install_config_file_package(CONFIGURE_PACKAGE_CONFIG_FILES TARGETS libheaders::libheaders)
jcm_create_clang_format_targets(VERBOSE TARGETS libheaders::libheaders)
