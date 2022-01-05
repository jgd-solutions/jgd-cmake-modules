# TODO: Try to find a way to install cmake-modules so test projects can consume
# cmake-modules with the find_package() pattern that real consumers would. Then,
# can remove CMAKE_MODULE_PATH in below tests.

macro(_TEST_PROJECT proj_name build_opts)
  add_test(
    NAME ${proj_name}
    COMMAND
      "${CMAKE_CTEST_COMMAND}" --build-and-test
      "${CMAKE_CURRENT_SOURCE_DIR}/${proj_name}"
      "${CMAKE_CURRENT_BINARY_DIR}/${proj_name}" --build-generator
      "${CMAKE_GENERATOR}" --build-options
      "-DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}" ${build_opts} --test-command
      "${CMAKE_CTEST_COMMAND}")
endmacro()

_test_project("single-exec" "")
_test_project("libcomponents" "")
_test_project("libdocs-proj" "-DBUILD_DOCS=ON")
