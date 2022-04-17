# TODO: Try to find a way to install cmake-modules so test projects can consume
# cmake-modules with the find_package() pattern that real consumers would. Then,
# can remove CMAKE_MODULE_PATH in below tests.
macro(_TEST_PROJECT project_name build_opts)
  set(name_suffix ${ARGN})
  add_test(
    NAME ${project_name}${name_suffix}
    COMMAND
    "${CMAKE_CTEST_COMMAND}" --build-and-test
    "${CMAKE_CURRENT_SOURCE_DIR}/${project_name}"
    "${CMAKE_CURRENT_BINARY_DIR}/${project_name}" --build-generator
    "${CMAKE_GENERATOR}" --build-options
    "-DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}" ${build_opts} --test-command
    "${CMAKE_CTEST_COMMAND}")
endmacro()

_test_project(single-exec "-DSINGLE_EXEC_BUILD_TESTS=ON")
_test_project("libsingle" "-DLIBSINGLE_BUILD_TESTS=ON")
_test_project("libsingle" "-DLIBSINGLE_BUILD_TESTS=ON -DLIBSINGLE_BUILD_SHARED_LIBS=ON" -shared)
#_test_project("libcomponents" "-DCOMPONENTS_BUILD_TESTS=ON")
