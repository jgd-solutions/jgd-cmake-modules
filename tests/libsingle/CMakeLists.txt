cmake_minimum_required(VERSION 3.20)
project(libsingle LANGUAGES CXX)

if(BUILD_DOCS)
  find_package(Doxygen REQUIRED COMPONENTS doxygen)
endif()

include(JgdSetupProject)
include(JgdClangFormat)
jgd_setup_project(WITH_TESTS WITH_DOCS CONFIGURE_CONFIG_HEADER
                  ADD_SUBDIRECTORIES)
jgd_create_clang_format_targets()
