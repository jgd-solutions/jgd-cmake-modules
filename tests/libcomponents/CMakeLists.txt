cmake_minimum_required(VERSION 3.20)
project(libcomponents VERSION 0.0.0 LANGUAGES CXX)

include(JgdSetupProject)
include(JgdSourceSubdirectories)
include(JgdStandardDirs)
include(JgdConfigureFiles)

jgd_setup_project()
jgd_source_subdirectories(ADD_SUBDIRS WITH_TESTS_DIR LIB_COMPONENTS core extra)
jgd_configure_config_header_file()
