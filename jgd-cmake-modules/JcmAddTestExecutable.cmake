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
include(JcmTargetSources)


#[=======================================================================[.rst:

jcm_add_test_executable
^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_add_test_executable

  .. code-block:: cmake

    jcm_add_test_executable(
      NAME <name>
      [TEST_NAME <test-name>]
      [LIBS <lib>...]
      SOURCES <source>...)

A convenience function to create an executable and add it as a test in one command, while also
setting target properties. This function has no affect if
:cmake:`${JCM_PROJECT_PREFIX_NAME}_BUILD_TESTS` is not set.

This function will:

- verify the naming conventions of the input source files, and transform them to absolute paths.
- create an executable with name NAME from SOURCES.
- register this executable as a test via CTest with name TEST_NAME, or NAME, if TEST_NAME is not
  provided.
- set target properties:

  - OUTPUT_NAME
  - COMPILE_OPTIONS
  - LINK_LIBRARIES
  - INCLUDE_DIRECTORIES

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
    OUT_TARGET target
    SOURCES main.cpp
    LIB_SOURCES engine.cpp)

  jcm_add_test_executable(
    NAME test_engine
    SOURCES test_engine.cpp
    LIBS ${target}-library Boost::ut)

#]=======================================================================]
function(jcm_add_test_executable)
  if(NOT ${JCM_PROJECT_PREFIX_NAME}_BUILD_TESTS)
    return()
  endif()

  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "NAME;TEST_NAME"
    MULTI_VALUE_KEYWORDS "SOURCES;LIBS"
    REQUIRES_ALL "NAME;SOURCES"
    ARGUMENTS "${ARGN}")

  jcm_verify_sources(
    TARGET_TYPE "EXECUTABLE"
    TARGET_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}"
    TARGET_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}"
    SOURCES "${ARGS_SOURCES}"
    OUT_PRIVATE_HEADERS test_headers
    OUT_SOURCES test_sources)

  # Additional naming verification for unit test sources
  if(NOT CMAKE_CURRENT_SOURCE_DIR MATCHES "^${JCM_PROJECT_TESTS_DIR}")
    jcm_separate_list(
      INPUT "${test_sources}"
      REGEX "${JCM_UTEST_SOURCE_REGEX}"
      TRANSFORM "FILENAME"
      OUT_MISMATCHED incorrectly_named)
    if(incorrectly_named)
      message(
        FATAL_ERROR
        "Provided source files do not match the regex for unit test executable sources, "
        "'${JCM_UTEST_SOURCE_REGEX}': ${incorrectly_named}.")
    endif()
  endif()


  # Default test name
  if(DEFINED ARGS_TEST_NAME)
    set(test_name "${ARGS_TEST_NAME}")
  else()
    set(test_name "${ARGS_NAME}")
  endif()

  # Test executable
  add_executable(${ARGS_NAME} "${ARGS_SOURCES}")
  add_test(NAME ${test_name} COMMAND ${ARGS_NAME})

  # Default properties
  set_target_properties(
    ${ARGS_NAME}
    PROPERTIES OUTPUT_NAME ${ARGS_NAME}
    COMPILE_OPTIONS "${JCM_DEFAULT_COMPILE_OPTIONS}"
    LINK_LIBRARIES "${ARGS_LIBS}")
endfunction()
