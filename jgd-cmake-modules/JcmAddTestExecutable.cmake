include_guard()

#[=======================================================================[.rst:

JcmAddTestExecutable
--------------------

#]=======================================================================]

include(JcmParseArguments)
include(JcmDefaultCompileOptions)
include(JcmFileNaming)
include(JcmStandardDirs)
include(JcmListTransformations)

#[=======================================================================[.rst:

.. cmake:command:: jcm_add_test_executable

  .. code-block:: cmake

    jcm_add_test_executable(
      NAME <name>
      [TEST_NAME <test-name>]
      [LIBS <lib>...]
      SOURCES <source>...
    )

A convenience function to create an executable and add it as a test in one command, while also
setting target properties. This function has no affect if <JCM_PROJECT_PREFIX_NAME>_BUILD_TESTS is
not set.

This function will:

- verify the naming conventions of the input source files, and transform them to absolute paths.
- create an executable with name NAME from SOURCES.
- register this executable as a test via CTest with name TEST_NAME, or NAME, if TEST_NAME is not
  provided.
- set target properties:

  - OUTPUT_NAME
  - COMPILE_OPTIONS
  - LINK_LIBRARIES

Parameters
##########

One Value
~~~~~~~~~~

:cmake:variable:`NAME`
  Sets the target name and output name of the created executable. Used as the default test name if
  :cmake:variable:`TEST_NAME` is not provided.

:cmake:variable:`TEST_NAME`
  Sets the test name to be registered with CTest.


Multi Value
~~~~~~~~~~~

:cmake:variable:`LIBS`
  Libraries to privately link against the created executable. Commonly the library that the created
  executable will test, and a testing framework.

:cmake:variable:`SOURCES`
  Sources used to create the executable

Examples
########

.. code-block:: cmake

  jcm_add_test_executable(NAME my_test SOURCES my_test.cpp)

.. code-block:: cmake

  jcm_add_executable(
    OUT_TARGET_NAME target
    SOURCES main.cpp
    OBJ_SOURCES engine.cpp
  )

  jcm_add_test_executable(
    NAME test_engine
    SOURCES test_engine.cpp
    LIBS ${target}-objects Boost::ut
  )


#]=======================================================================]
function(jcm_add_test_executable)
  if (NOT ${JCM_PROJECT_PREFIX_NAME}_BUILD_TESTS)
    return()
  endif ()

  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "NAME;TEST_NAME"
    MULTI_VALUE_KEYWORDS "SOURCES;LIBS"
    REQUIRES_ALL "NAME;SOURCES"
    ARGUMENTS "${ARGN}")

  # Verify source naming

  if (CMAKE_CURRENT_SOURCE_DIR MATCHES "^${JCM_PROJECT_TESTS_DIR}")
    set(test_source_regex "${JCM_SOURCE_REGEX}") # other tests & drivers, only
  else ()
    set(test_source_regex "${JCM_TEST_SOURCE_REGEX}") # unit test files, only
  endif ()

  set(regex "${JCM_HEADER_REGEX}|${test_source_regex}")
  jcm_separate_list(
    IN_LIST "${ARGS_SOURCES};${ARGS_MAIN_SOURCES}"
    REGEX "${regex}"
    TRANSFORM "FILENAME"
    OUT_UNMATCHED incorrectly_named
  )
  if (incorrectly_named)
    message(
      FATAL_ERROR
      "Provided source files do not match the regex for test executable sources, ${regex}: "
      "${incorrectly_named}.")
  endif ()

  # Default test name
  set(test_name "${ARGS_NAME}")
  if (DEFINED ARGS_TEST_NAME)
    set(test_name "${ARGS_TEST_NAME}")
  endif ()

  # Test executable
  jcm_transform_list(ABSOLUTE_PATH INPUT "${ARGS_SOURCES}" OUT_VAR abs_sources)
  add_executable(${ARGS_NAME} "${abs_sources}")
  add_test(NAME ${test_name} COMMAND ${ARGS_NAME})

  # Default properties
  set_target_properties(
    ${ARGS_NAME}
    PROPERTIES OUTPUT_NAME ${ARGS_NAME}
    COMPILE_OPTIONS "${JCM_DEFAULT_COMPILE_OPTIONS}"
    LINK_LIBRARIES "${ARGS_LIBS}")
endfunction()
