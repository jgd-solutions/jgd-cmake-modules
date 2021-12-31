cmake_minimum_required(VERSION 3.15)
project(cmake-modules LANGUAGES NONE)
include(CTest)

set(module_dir "${CMAKE_CURRENT_SOURCE_DIR}/cmake-modules")
list(APPEND CMAKE_MODULE_PATH "${module_dir}")
include(JgdInstallTargets)

add_library(${PROJECT_NAME} INTERFACE)

file(GLOB module_files "${module_dir}/*.cmake")
message(STATUS "files : ${}")
jgd_install_targets(TARGETS ${PROJECT_NAME} CMAKE_MODULES "${module_files}")
