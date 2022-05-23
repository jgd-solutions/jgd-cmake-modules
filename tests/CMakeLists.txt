include(JgdParseArguments)
include(JgdStandardDirs)

set(jgd-cmake-modules_ROOT "${CMAKE_CURRENT_BINARY_DIR}/install")

function(_build_and_ctest project_name)
  jgd_parse_arguments(
    ONE_VALUE_KEYWORDS "NAME_SUFFIX" "BUILD_TARGET"
    MULTI_VALUE_KEYWORDS "BUILD_OPTIONS"
    ARGUMENTS "${ARGN}")

  if(NOT ARGS_BUILD_TARGET)
    set(ARGS_BUILD_TARGET all)
    set(test_arg --test-command "${CMAKE_CTEST_COMMAND}")
  else()
    unset(test_arg)
  endif()

  add_test(
    NAME ${project_name}${ARGS_NAME_SUFFIX}
    COMMAND
    "${CMAKE_CTEST_COMMAND}"
    --verbose
    --output-on-failure
    --build-noclean
    --build-generator "${CMAKE_GENERATOR}"
    --build-target ${ARGS_BUILD_TARGET}
    --build-and-test "${CMAKE_CURRENT_SOURCE_DIR}/${project_name}" "${CMAKE_CURRENT_BINARY_DIR}/${project_name}"
    --build-options "-Djgd-cmake-modules_ROOT:PATH=${jgd-cmake-modules_ROOT}" ${ARGS_BUILD_OPTIONS}
    ${test_arg})
endfunction()


function(_install_use_project project_name)
  set(${project_name}_ROOT "${CMAKE_CURRENT_BINARY_DIR}/${project_name}/install")

  add_test(
    NAME ${project_name}-install
    COMMAND
    "${CMAKE_COMMAND}"
    --install "${CMAKE_CURRENT_BINARY_DIR}/${project_name}"
    --verbose
    --prefix "${${project_name}_ROOT}")

  add_test(
    NAME ${project_name}-use-install
    COMMAND
    "${CMAKE_CTEST_COMMAND}"
    --verbose
    --output-on-failure
    --build-noclean
    --build-generator "${CMAKE_GENERATOR}"
    --build-and-test
      "${CMAKE_CURRENT_SOURCE_DIR}/test-project-consumption"
      "${CMAKE_CURRENT_BINARY_DIR}/test-project-consumption"
    --build-options
      "-D TEST_PROJECT_CONSUMPTION_BUILD_TESTS:BOOL=ON"
      "-D jgd-cmake-modules_ROOT:PATH=${jgd-cmake-modules_ROOT}"
      "-D ${project_name}_ROOT:PATH=${${project_name}_ROOT}"
      "-D test_name=use-${project_name}"
      "-D components=${ARGN}"
    --test-command "${CMAKE_CTEST_COMMAND}")
endfunction()


# Install jgd-cmake-modules as a test and for following test projects to find
add_test(
  NAME ${PROJECT_NAME}-install
  COMMAND
  "${CMAKE_COMMAND}"
  --install "${PROJECT_BINARY_DIR}"
  --verbose
  --prefix "${jgd-cmake-modules_ROOT}")


# == single-exec ==

_build_and_ctest("single-exec"
  BUILD_OPTIONS -DSINGLE_EXEC_BUILD_TESTS=ON
  NAME_SUFFIX -format
  BUILD_TARGET clang-format-check)

_build_and_ctest("single-exec"
  BUILD_OPTIONS -DSINGLE_EXEC_BUILD_TESTS=ON)

_install_use_project("single-exec")


# == libsingle ==

_build_and_ctest("libsingle"
  BUILD_OPTIONS -DLIBSINGLE_BUILD_TESTS=ON
  NAME_SUFFIX -format
  BUILD_TARGET clang-format-check)

_build_and_ctest("libsingle"
  BUILD_OPTIONS -DLIBSINGLE_BUILD_TESTS=ON)

_build_and_ctest("libsingle"
  BUILD_OPTIONS -DLIBSINGLE_BUILD_TESTS=ON -DLIBSINGLE_BUILD_SHARED_LIBS=ON
  NAME_SUFFIX -shared)

_build_and_ctest("libsingle"
  BUILD_OPTIONS -DLIBSINGLE_BUILD_TESTS=ON -DLIBSINGLE_BUILD_DOCS=ON
  NAME_SUFFIX -docs
  BUILD_TARGET doxygen-docs)

_install_use_project("libsingle")


# == libcomponents ==

_build_and_ctest("libcomponents"
  BUILD_OPTIONS -DLIBCOMPONENTS_BUILD_TESTS=ON
  NAME_SUFFIX -format
  BUILD_TARGET clang-format-check)

_build_and_ctest("libcomponents"
  BUILD_OPTIONS -DLIBCOMPONENTS_BUILD_TESTS=ON)

_build_and_ctest("libcomponents"
  BUILD_OPTIONS -DLIBCOMPONENTS_BUILD_TESTS=ON -DLIBCOMPONENTS_CORE_BUILD_SHARED_LIBS=ON
  NAME_SUFFIX -shared)

_install_use_project("libcomponents" core extra)


# == libheaders ==

_build_and_ctest("libheaders"
  BUILD_OPTIONS -DLIBHEADERS_BUILD_TESTS=ON
  NAME_SUFFIX -format
  BUILD_TARGET clang-format-check)

_build_and_ctest("libheaders"
  BUILD_OPTIONS -DLIBHEADERS_BUILD_TESTS=ON)

_install_use_project("libheaders")
