cmake_minimum_required(VERSION 3.20)
project(libdoxydocs VERSION 0.0.0 LANGUAGES CXX)

if (LIBDOXYDOCS_BUILD_DOCS)
  find_package(Doxygen REQUIRED COMPONENTS doxygen)
endif ()

include(JgdSetupProject)
include(JgdSourceSubdirectories)
include(JgdStandardDirs)
include(JgdConfigureFiles)

jgd_setup_project()
jgd_source_subdirectories(ADD_SUBDIRS WITH_TESTS_DIR WITH_DOCS_DIR)
jgd_configure_config_header_file()
