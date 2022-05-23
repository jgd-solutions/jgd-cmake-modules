cmake_minimum_required(VERSION 3.23)
project(test-project-consumption VERSION 0.0.0 LANGUAGES CXX)

# == Usage Guards ==
if(NOT DEFINED test_name)
  message(FATAL_ERROR "The project ${PROJECT_NAME} must be called with test_name set")
endif()

if(NOT DEFINED jgd-cmake-modules_ROOT)
  message(FATAL_ERROR "jgd-cmake-modules_ROOT should be set to the root of the one installed during "
    "testing to ensure that the correct one under test is found.")
endif()

# == Find Package Under Test ==

if(components)
  set(comp_arg COMPONENTS ${components})
else()
  unset(comp_arg)
endif()
string(REGEX REPLACE "^use-" "" package_name "${test_name}")
find_package(${package_name} CONFIG REQUIRED ${comp_arg})

# == Create Tests to Use Package ==

if(test_name STREQUAL use-single-exec)
  add_test(NAME ${test_name} COMMAND single-exec::single-exec)
  return()
elseif(test_name STREQUAL use-libsingle)
  add_executable(${test_name} use_libsingle.cpp)
  target_link_libraries(${test_name} PRIVATE libsingle::libsingle)
elseif(test_name STREQUAL use-libcomponents)
  add_executable(${test_name} use_libcomponents.cpp)
  target_link_libraries(${test_name} PRIVATE libcomponents::extra)
elseif(test_name STREQUAL use-libheaders)
  add_executable(${test_name} use_libheaders.cpp)
  target_link_libraries(${test_name} PRIVATE libheaders::libheaders)
else()
  message(FATAL_ERROR "${test_name} is not a recognized test name in ${PROJECT_NAME}")
endif()

add_test(NAME ${test_name} COMMAND ${test_name})
