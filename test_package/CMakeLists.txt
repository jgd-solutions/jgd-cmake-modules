cmake_minimum_required(VERSION 3.20)
project(test-package CXX)

find_package(cmake-modules CONFIG REQUIRED)
include(JgdSetupProject)

jgd_setup_project(ADD_SUBDIRECTORIES)
# CTest is a testing tool that can be used to test your project.
# enable_testing() add_test(NAME example WORKING_DIRECTORY
# ${CMAKE_BINARY_DIR}/bin COMMAND example)
