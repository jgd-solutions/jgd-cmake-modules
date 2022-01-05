# TODO: Try to find a way to install cmake-modules so test projects can consume
# cmake-modules with the find_package() pattern that real consumers would. Then,
# can remove CMAKE_MODULE_PATH in below tests.

add_test(
  NAME single-exec-project
  COMMAND
    "${CMAKE_CTEST_COMMAND}" --build-and-test
    "${CMAKE_CURRENT_SOURCE_DIR}/single-exec-project"
    "${CMAKE_CURRENT_BINARY_DIR}/single-exec-project" --build-generator
    "${CMAKE_GENERATOR}" --build-options
    "-DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}" --test-command
    "${CMAKE_CTEST_COMMAND}")

add_test(
  NAME libcomp-project
  COMMAND
    "${CMAKE_CTEST_COMMAND}" --build-and-test
    "${CMAKE_CURRENT_SOURCE_DIR}/libcomp-project"
    "${CMAKE_CURRENT_BINARY_DIR}/libcomp-project" --build-generator
    "${CMAKE_GENERATOR}" --build-options
    "-DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}" --test-command
    "${CMAKE_CTEST_COMMAND}")
