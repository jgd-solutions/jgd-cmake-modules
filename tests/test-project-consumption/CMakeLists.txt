cmake_minimum_required(VERSION 3.23)
project(test-project-consumption VERSION 0.0.0 LANGUAGES CXX)
enable_testing()

# == Usage Guards ==
if(NOT DEFINED test_name)
  message(FATAL_ERROR "The project ${PROJECT_NAME} must be called with test_name set")
endif()

if(NOT DEFINED jgd-cmake-modules_ROOT)
  message(FATAL_ERROR "jgd-cmake-modules_ROOT should be set to the root of the one installed during "
    "testing to ensure that the correct one under test is found.")
endif()

if(NOT DEFINED consumption_type OR NOT consumption_type MATCHES "FIND_PACKAGE|ADD_SUBDIRECTORY")
  message(FATAL_ERROR "'consumption_type' must be defined to either FIND_PACKAGE or "
    "ADD_SUBDIRECTORY for ${PROJECT_NAME}")
endif()

# == Find or Add Package Under Test ==

string(REGEX REPLACE "^.*-use-" "" package_name "${test_name}")

if(consumption_type STREQUAL FIND_PACKAGE)
  if(components)
    set(comp_arg COMPONENTS ${components})
  else()
    unset(comp_arg)
  endif()

  find_package(${package_name} CONFIG REQUIRED ${comp_arg})
else()
  add_subdirectory(contrib/${package_name})
  set(components ${components}) # use components variable
endif()

# == Create Tests to Use Package ==

if(test_name MATCHES "single-exec")
  add_test(NAME ${test_name} COMMAND single-exec::single-exec)
  return()
elseif(test_name MATCHES "many-exec")

  if(components MATCHES "compiler")
    add_test(NAME ${test_name}-compiler COMMAND many-exec::compiler arg)
  endif()
  if(components MATCHES "formatter")
    add_test(NAME ${test_name}-formatter COMMAND many-exec::formatter arg)
  endif()
  return()

elseif(test_name MATCHES "libsingle")
  add_executable(${test_name} use_libsingle.cpp)
  target_link_libraries(${test_name} PRIVATE libsingle::libsingle)
elseif(test_name MATCHES "libcomponents")

  if(NOT components OR components MATCHES "extra")
    add_executable(${test_name} use_libcomponents_extra.cpp)
    target_link_libraries(${test_name} PRIVATE libcomponents::extra)
  elseif(components MATCHES "core")
    add_executable(${test_name} use_libcomponents_core.cpp)
    target_link_libraries(${test_name} PRIVATE libcomponents::core)
  elseif()
    message(
      FATAL_ERROR
      "No recognized components specified for testing libcomponents: ${components}"
    )
  endif()

elseif(test_name MATCHES "libheaders")
  add_executable(${test_name} use_libheaders.cpp)
  target_link_libraries(${test_name} PRIVATE libheaders::libheaders)
else()
  message(FATAL_ERROR "${test_name} is not a recognized test name in ${PROJECT_NAME}")
endif()

add_test(NAME ${test_name} COMMAND ${test_name})
