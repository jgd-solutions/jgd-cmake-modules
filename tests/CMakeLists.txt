# Install cmake-modules so test projects can consume cmake-modules with the
# find_package() pattern that real consumers would

add_test(
  NAME single-exec-project
  COMMAND
    "${CMAKE_CTEST_COMMAND}" --build-and-test
    "${CMAKE_CURRENT_SOURCE_DIR}/single-exec-project"
    "${CMAKE_CURRENT_BINARY_DIR}/single-exec-project" --build-generator
    "${CMAKE_GENERATOR}" --build-options
    "-DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}" --test-command
    "${CMAKE_CTEST_COMMAND}")
