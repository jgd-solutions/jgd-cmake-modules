include(JcmParseArguments)
include(JcmStandardDirs)

set(jgd-cmake-modules_ROOT "${CMAKE_CURRENT_BINARY_DIR}/install")

function(_create_ctest_test test_name)
  jcm_parse_arguments(
    OPTIONS "RUN_INNER_CTEST"
    ONE_VALUE_KEYWORDS "TEST_NAME" "PROJECT_NAME" "BUILD_TARGET"
    MULTI_VALUE_KEYWORDS "BUILD_OPTIONS"
    REQUIRES_ALL "PROJECT_NAME"
    ARGUMENTS "${ARGN}")

  if (DEFINED ARGS_RUN_INNER_CTEST)
    set(ctest_argument --test-command "${CMAKE_CTEST_COMMAND}" --build-config ${CMAKE_BUILD_TYPE})
  else ()
    unset(ctest_argument)
  endif ()

  if (ARGS_BUILD_TARGET)
    set(build_target_argument --build-target ${ARGS_BUILD_TARGET})
  else ()
    unset(build_target_argument)
  endif ()

  add_test(
    NAME ${test_name}
    COMMAND
    "${CMAKE_CTEST_COMMAND}"
    --verbose
    --output-on-failure
    --build-noclean
    --build-generator "${CMAKE_GENERATOR}"
    --build-config ${CMAKE_BUILD_TYPE}
    --build-and-test
    "${CMAKE_CURRENT_SOURCE_DIR}/${ARGS_PROJECT_NAME}"
    "${CMAKE_CURRENT_BINARY_DIR}/${ARGS_PROJECT_NAME}"
    --build-options
    "-Djgd-cmake-modules_ROOT:PATH=${jgd-cmake-modules_ROOT}"
    ${ARGS_BUILD_OPTIONS}
    ${ctest_argument})
endfunction()

function(_build_and_ctest project_name)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "NAME_SUFFIX" "BUILD_TARGET"
    MULTI_VALUE_KEYWORDS "BUILD_OPTIONS" "DEPENDS"
    ARGUMENTS "${ARGN}")

  # not running ctest when target specified is specific to JCM's tests
  if (ARGS_BUILD_TARGET)
    set(build_target_arg BUILD_TARGET ${ARGS_BUILD_TARGET})
    unset(run_inner_ctest)
  else ()
    unset(build_target_arg)
    set(run_inner_ctest RUN_INNER_CTEST)
  endif ()

  set(test_name "${project_name}${ARGS_NAME_SUFFIX}")
  _create_ctest_test(${test_name}
    ${run_inner_ctest}
    PROJECT_NAME ${project_name}
    BUILD_OPTIONS "${ARGS_BUILD_OPTIONS}"
    ${build_target_arg})

  set_tests_properties(${test_name} PROPERTIES RESOURCE_LOCK "build-${project_name}")
  if (DEFINED ARGS_DEPENDS)
    set_tests_properties(${test_name} PROPERTIES DEPENDS "${ARGS_DEPENDS}")
  endif ()
endfunction()


function(_install_project project_name)
  jcm_parse_arguments(MULTI_VALUE_KEYWORDS "DEPENDS" ARGUMENTS "${ARGN}")

  set(${project_name}_ROOT "${CMAKE_CURRENT_BINARY_DIR}/${project_name}/install")
  set(${project_name}_ROOT "${${project_name}_ROOT}" PARENT_SCOPE)
  set(test_name ${project_name}-install)

  add_test(
    NAME ${test_name}
    COMMAND
    "${CMAKE_COMMAND}"
    --install "${CMAKE_CURRENT_BINARY_DIR}/${project_name}"
    --verbose
    --prefix "${${project_name}_ROOT}")

  if (DEFINED ARGS_DEPENDS)
    set_tests_properties(${test_name} PROPERTIES DEPENDS "${ARGS_DEPENDS}")
  endif ()
endfunction()


function(_find_use_project project_name)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "OUT_TEST_NAME"
    MULTI_VALUE_KEYWORDS "COMPONENTS" "DEPENDS"
    ARGUMENTS "${ARGN}")

  if (ARGS_COMPONENTS)
    set(specified_components "${ARGS_COMPONENTS}")
    string(REPLACE ";" "-" test_name_suffix "${specified_components}")
    set(test_name_suffix "-${test_name_suffix}")
  else ()
    unset(specified_components)
    unset(test_name_suffix)
  endif ()

  set(${project_name}_ROOT "${CMAKE_CURRENT_BINARY_DIR}/${project_name}/install")
  set(test_name "${project_name}-find-use${test_name_suffix}")

  _create_ctest_test(${test_name}
    RUN_INNER_CTEST
    PROJECT_NAME test-project-consumption
    BUILD_OPTIONS
    "-D consumption_type=FIND_PACKAGE"
    "-D ${project_name}_ROOT:PATH=${${project_name}_ROOT}"
    "-D test_name=find-use-${project_name}"
    "-D components=${specified_components}")

  set_tests_properties(${test_name} PROPERTIES RESOURCE_LOCK "test-project-consumption")

  if (DEFINED ARGS_OUT_TEST_NAME)
    set(${ARGS_OUT_TEST_NAME} ${test_name} PARENT_SCOPE)
  endif ()

  if (DEFINED ARGS_DEPENDS)
    set_tests_properties(${test_name} PROPERTIES DEPENDS "${ARGS_DEPENDS}")
  endif ()
endfunction()


function(_add_use_project project_name)
  jcm_parse_arguments(MULTI_VALUE_KEYWORDS "DEPENDS" ARGUMENTS "${ARGN}")
  set(test_name ${project_name}-add-use)

  _create_ctest_test(${test_name}
    RUN_INNER_CTEST
    PROJECT_NAME test-project-consumption
    BUILD_OPTIONS
    "-D consumption_type=ADD_SUBDIRECTORY"
    "-D test_name=add-use-${project_name}"
    "-D components=${ARGN}")

  set_tests_properties(${test_name} PROPERTIES RESOURCE_LOCK "test-project-consumption")

  if (DEFINED ARGS_DEPENDS)
    set_tests_properties(${test_name} PROPERTIES DEPENDS "${ARGS_DEPENDS}")
  endif ()
endfunction()

function(_file_exists project_name test_suffix file_path)
  jcm_parse_arguments(MULTI_VALUE_KEYWORDS "DEPENDS" ARGUMENTS "${ARGN}")
  set(test_name "${project_name}${test_suffix}")

  add_test(
    NAME ${test_name}
    COMMAND "${CMAKE_COMMAND}" -E rename "${file_path}" "${file_path}")

  if (DEFINED ARGS_DEPENDS)
    set_tests_properties(${test_name} PROPERTIES DEPENDS "${ARGS_DEPENDS}")
  endif ()
endfunction()
