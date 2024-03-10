include_guard()

#[=======================================================================[.rst:

JcmAddTestExecutable
--------------------

:github:`JcmAddTestExecutable`

#]=======================================================================]

include(JcmParseArguments)
include(JcmDefaultCompileOptions)
include(JcmFileNaming)
include(JcmStandardDirs)
include(JcmCanonicalStructure) # JCM_CANONICAL_SUBDIR_PREFIX_REGEX
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

- verify the input source files using :cmake:command:`jcm_verify_target_sources`, and use the
  cleaned sources produced by that function.
- create an executable with name :cmake:variable:`NAME` from :cmake:variable:`SOURCES`.
- register this executable as a test via CTest with name :cmake:variable:`TEST_NAME`, which
  defaults to :cmake:variable:`NAME`, if :cmake:variable:`TEST_NAME` isn't provided.
- creates a private header set
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

  # Additional naming considerations for unit test sources
  jcm_separate_list(
    INPUT "${ARGS_SOURCES}"
    REGEX "${JCM_UTEST_SOURCE_REGEX}"
    TRANSFORM "FILENAME"
    OUT_MATCHED unit_test_sources
    OUT_MISMATCHED standard_sources)

  if(unit_test_sources AND
    NOT CMAKE_CURRENT_SOURCE_DIR MATCHES "${JCM_PROJECT_CANONICAL_SUBDIR_PREFIX_REGEX}")
    message(FATAL_ERROR
      "The '.test' file extension is reserved for unit test sources. ${CMAKE_CURRENT_FUNCTION} is "
      "being called to create target '${ARGS_NAME}' with unit test source files outside of a "
      "canonical target subdirectory: ${unit_test_sources}")
  endif()

  if(standard_sources)
    jcm_verify_sources(
      TARGET_TYPE "EXECUTABLE"
      TARGET_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}"
      TARGET_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}"
      SOURCES "${standard_sources}"
      OUT_PRIVATE_HEADERS test_headers
      OUT_SOURCES standard_test_sources)
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
