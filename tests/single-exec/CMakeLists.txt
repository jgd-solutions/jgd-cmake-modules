cmake_minimum_required(VERSION 3.20)
project(single-exec VERSION 0.0.0 LANGUAGES CXX)

#find_package(jgd-cmake-modules CONFIG REQUIRED)
include(JgdAllModules)

jgd_setup_project()
jgd_source_subdirectories(ADD_SUBDIRS WITH_TESTS_DIR)
jgd_configure_config_header_file()
jgd_create_clang_format_targets(TARGETS single-exec::single-exec)
