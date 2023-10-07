cmake_minimum_required(VERSION 3.24)
project(test-project-consumption VERSION 0.0.0)
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
  find_package(jgd-cmake-modules CONFIG REQUIRED)
  add_subdirectory(contrib) # uses package_name
  set(components ${components}) # use components variable
endif()

# == For Windows, since tests run from build tree, not install tree  ==

function(__copy_dependency_dlls test_exec_target out_test_names)
  if(NOT CMAKE_SYSTEM_NAME STREQUAL "Windows")
    return()
  endif()

  foreach(dependent_target IN LISTS ARGN)
    get_target_property(is_imported ${dependent_target} IMPORTED)
    get_target_property(target_type ${dependent_target} TYPE)
    if(NOT is_imported OR NOT ${target_type} STREQUAL "SHARED_LIBRARY")
      continue()
    endif()

    get_target_property(dll_loc ${dependent_target} LOCATION)
    if(NOT dll_loc)
      continue()
    endif()

    set(copy_test_name "copy-${dependent_target}-dll-for-${test_exec_target}")
    list(APPEND copy_test_names "${copy_test_name}")
    add_test(NAME "${copy_test_name}"
      COMMAND "${CMAKE_COMMAND}"
      -E copy
      "$<TARGET_FILE:${dependent_target}>"
      "$<TARGET_FILE_DIR:${test_exec_target}>")
  endforeach()

  set(${out_test_names} ${copy_test_names} PARENT_SCOPE)
endfunction()


# == Create Targets to Use Package ==

unset(copy_dll_tests)

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
  __copy_dependency_dlls(${test_name} copy_dll_tests libsingle::libsingle)

elseif(test_name MATCHES "libcomponents")
  if(NOT components OR components MATCHES "extra")
    add_executable(${test_name} use_libcomponents_extra.cpp)
    target_link_libraries(${test_name} PRIVATE libcomponents::extra)
  elseif(components MATCHES "core")
    add_executable(${test_name} use_libcomponents_core.cpp)
    target_link_libraries(${test_name} PRIVATE libcomponents::core)
    __copy_dependency_dlls(${test_name} copy_dll_tests libcomponents::core)
  elseif()
    message(
      FATAL_ERROR
      "No recognized components specified for testing libcomponents: ${components}")
  endif()

elseif(test_name MATCHES "libheaders")
  add_executable(${test_name} use_libheaders.cpp)
  target_link_libraries(${test_name} PRIVATE libheaders::libheaders)

elseif(test_name MATCHES "libcstr")
  add_executable(${test_name} use_libcstr.c)
  target_link_libraries(${test_name} PRIVATE libcstr::libcstr)

else()
  message(FATAL_ERROR "${test_name} is not a recognized test name in ${PROJECT_NAME}")
endif()


# == Create Tests from Created Library Target ==

add_test(NAME ${test_name} COMMAND ${test_name})

if(copy_dll_tests)
  set_tests_properties(${test_name} PROPERTIES DEPENDS ${copy_dll_tests})
endif()
