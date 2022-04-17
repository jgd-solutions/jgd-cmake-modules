cmake_minimum_required(VERSION 3.20)
project(single-exec VERSION 0.0.0 LANGUAGES CXX)

include(JgdSetupProject)
include(JgdSourceSubdirectories)
include(JgdConfigureFiles)

jgd_setup_project()
jgd_configure_config_header_file()
jgd_source_subdirectories(ADD_SUBDIRS)
add_subdirectory("${JGD_PROJECT_TESTS_DIR}")