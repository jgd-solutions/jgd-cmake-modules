include(JcmParseArguments)
include(JcmStandardDirs)

set(jgd-cmake-modules_ROOT "${CMAKE_CURRENT_BINARY_DIR}/install")

function(_build_and_ctest project_name)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "NAME_SUFFIX" "BUILD_TARGET"
    MULTI_VALUE_KEYWORDS "BUILD_OPTIONS"
    ARGUMENTS "${ARGN}"
  )

  if (NOT ARGS_BUILD_TARGET)
    set(ARGS_BUILD_TARGET all)
    set(test_arg --test-command "${CMAKE_CTEST_COMMAND}")
  else ()
    unset(test_arg)
  endif ()

  add_test(
    NAME "${project_name}${ARGS_NAME_SUFFIX}"
    COMMAND
    "${CMAKE_CTEST_COMMAND}"
    --verbose
    --output-on-failure
    --build-noclean
    --build-generator "${CMAKE_GENERATOR}"
    --build-target ${ARGS_BUILD_TARGET}
    --build-and-test "${CMAKE_CURRENT_SOURCE_DIR}/${project_name}" "${CMAKE_CURRENT_BINARY_DIR}/${project_name}"
    --build-options "-Djgd-cmake-modules_ROOT:PATH=${jgd-cmake-modules_ROOT}" "-DCMAKE_VERBOSE_MAKEFILE=ON" ${ARGS_BUILD_OPTIONS}
    ${test_arg})
endfunction()


function(_install_project project_name)
  set(${project_name}_ROOT "${CMAKE_CURRENT_BINARY_DIR}/${project_name}/install")
  set(${project_name}_ROOT "${${project_name}_ROOT}" PARENT_SCOPE)

  add_test(
    NAME ${project_name}-install
    COMMAND
    "${CMAKE_COMMAND}"
    --install "${CMAKE_CURRENT_BINARY_DIR}/${project_name}"
    --verbose
    --prefix "${${project_name}_ROOT}")
endfunction()


function(_find_use_project project_name)
  jcm_parse_arguments(
    MULTI_VALUE_KEYWORDS "COMPONENTS"
    ARGUMENTS "${ARGN}"
  )

  if (ARGS_COMPONENTS)
    set(specified_components "${ARGS_COMPONENTS}")
    string(REPLACE ";" "-" test_name_suffix "${specified_components}")
    set(test_name_suffix "-${test_name_suffix}")
  else ()
    unset(specified_components)
    unset(test_name_suffix)
  endif ()

  set(${project_name}_ROOT "${CMAKE_CURRENT_BINARY_DIR}/${project_name}/install")

  add_test(
    NAME ${project_name}-find-use${test_name_suffix}
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
    "-D consumption_type=FIND_PACKAGE"
    "-D jgd-cmake-modules_ROOT:PATH=${jgd-cmake-modules_ROOT}"
    "-D ${project_name}_ROOT:PATH=${${project_name}_ROOT}"
    "-D test_name=find-use-${project_name}"
    "-D components=${specified_components}"
    --test-command "${CMAKE_CTEST_COMMAND}"
  )
endfunction()


function(_add_use_project project_name)
  add_test(
    NAME ${project_name}-add-use
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
    "-D consumption_type=ADD_SUBDIRECTORY"
    "-D jgd-cmake-modules_ROOT:PATH=${jgd-cmake-modules_ROOT}"
    "-D test_name=add-use-${project_name}"
    "-D components=${ARGN}"
    --test-command "${CMAKE_CTEST_COMMAND}")
endfunction()

function(_file_exists project_name test_suffix file_path)
  add_test(
    NAME "${project_name}${test_suffix}"
    COMMAND "${CMAKE_COMMAND}" -E rename "${file_path}" "${file_path}")
endfunction()
