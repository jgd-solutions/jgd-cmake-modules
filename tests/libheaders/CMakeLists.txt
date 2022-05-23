cmake_minimum_required(VERSION 3.23)
project(libheaders VERSION 0.0.0 LANGUAGES CXX)

find_package(jgd-cmake-modules CONFIG REQUIRED)
include(JgdAllModules)

jgd_setup_project()
jgd_source_subdirectories(ADD_SUBDIRS WITH_TESTS_DIR)
jgd_configure_config_header_file()
jgd_install_config_file_package(CONFIGURE_PACKAGE_CONFIG_FILES TARGETS libheaders::libheaders)
jgd_create_clang_format_targets(VERBOSE TARGETS libheaders::libheaders)

