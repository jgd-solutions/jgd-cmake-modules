include(JgdParseArguments)

# TODO: Try to find a way to install cmake-modules so test projects can consume
# cmake-modules with the find_package() pattern that real consumers would. Then,
# can remove CMAKE_MODULE_PATH in below tests.
macro(_TEST_PROJECT project_name)
  jgd_parse_arguments(
    ONE_VALUE_KEYWORDS
    "NAME_SUFFIX"
    "BUILD_TARGET"
    MULTI_VALUE_KEYWORDS
    "BUILD_OPTIONS"
    ARGUMENTS
    "${ARGN}")

  if (NOT ARGS_BUILD_TARGET)
    set(ARGS_BUILD_TARGET all)
  endif ()

  if (NOT DEFINED ARGS_BUILD_TARGET)
    set(test_command_argument --test-command "${CMAKE_CTEST_COMMAND}")
  endif ()

  add_test(
    NAME ${project_name}${ARGS_NAME_SUFFIX}
    COMMAND
    "${CMAKE_CTEST_COMMAND}"
    --build-target ${ARGS_BUILD_TARGET}
    --build-and-test "${CMAKE_CURRENT_SOURCE_DIR}/${project_name}" "${CMAKE_CURRENT_BINARY_DIR}/${project_name}"
    --build-generator "${CMAKE_GENERATOR}"
    --build-options "-DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}" ${ARGS_BUILD_OPTIONS}
    ${test_command_argument})
endmacro()

_test_project(single-exec
  BUILD_OPTIONS -DSINGLE_EXEC_BUILD_TESTS=ON)

_test_project("libsingle"
  BUILD_OPTIONS -DLIBSINGLE_BUILD_TESTS=ON)

_test_project("libsingle"
  BUILD_OPTIONS -DLIBSINGLE_BUILD_TESTS=ON -DLIBSINGLE_BUILD_SHARED_LIBS=ON
  NAME_SUFFIX -shared)

_test_project("libcomponents"
  BUILD_OPTIONS -DLIBCOMPONENTS_BUILD_TESTS=ON)

_test_project("libcomponents"
  BUILD_OPTIONS -DLIBCOMPONENTS_BUILD_TESTS=ON -DLIBCOMPONENTS_CORE_BUILD_SHARED_LIBS=ON
  NAME_SUFFIX -shared)

_test_project("libdoxydocs"
  BUILD_OPTIONS -DLIBDOXYDOCS_BUILD_TESTS=ON -DLIBDOXYDOCS_BUILD_DOCS=ON
  NAME_SUFFIX -proj-works)

_test_project("libdoxydocs"
  BUILD_OPTIONS -DLIBDOXYDOCS_BUILD_TESTS=ON -DLIBDOXYDOCS_BUILD_DOCS=ON
  BUILD_TARGET doxygen-docs)

_test_project("libcomponents"
  BUILD_OPTIONS -DLIBCOMPONENTS_BUILD_TESTS=ON
  NAME_SUFFIX -format
  BUILD_TARGET clang-format-check)
