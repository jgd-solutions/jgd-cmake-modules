cmake_minimum_required(VERSION 3.20)
project(libdocs-proj LANGUAGES CXX)

if(BUILD_DOCS)
  find_package(Doxygen REQUIRED COMPONENTS doxygen)
endif()

include(JgdSetupDefaultProject)
jgd_setup_default_project(WITH_TESTS WITH_DOCS ADD_SUBDIRECTORIES)
