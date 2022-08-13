include_guard()

include(JcmParseArguments)
include(JcmDefaultCompileOptions)
include(JcmFileNaming)
include(JcmStandardDirs)
include(JcmListTransformations)

#
# A convenience function to create an executable and add it as a test in one
# command, while also setting default target compile options from
# JcmDefaultCompileOptions. An executable with name EXECUTABLE will be created
# from the sources provided to SOURCES. This executable will then be registered
# as a test with name NAME, or EXECUTABLE, if NAME is not provided. This
# function has no affect if <JCM_PROJECT_PREFIX_NAME>_BUILD_TESTS is not set.
#
# Arguments:
#
# EXECUTABLE: one-value arg; the name of the test executable to generate.
#
# NAME: one-value arg; the name of the test to register with CTest. Optional -
# will be set to EXECUTABLE, if not provided.
#
# SOURCES: multi-value arg; the sources to create EXECUTABLE from.
#
# LIBS: multi value arg; list of libraries to privately link against the test
# executable. Commonly the library under test. Optional.
#
function(jcm_add_test_executable)
  if (NOT ${JCM_PROJECT_PREFIX_NAME}_BUILD_TESTS)
    return()
  endif ()

  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "EXECUTABLE;NAME"
    MULTI_VALUE_KEYWORDS "SOURCES;LIBS"
    REQUIRES_ALL "EXECUTABLE;SOURCES"
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
  set(test_name "${ARGS_EXECUTABLE}")
  if (DEFINED ARGS_NAME)
    set(test_name "${ARGS_NAME}")
  endif ()

  # Test executable
  jcm_transform_list(ABSOLUTE_PATH INPUT "${ARGS_SOURCES}" OUT_VAR abs_sources)
  add_executable(${ARGS_EXECUTABLE} "${abs_sources}")
  add_test(NAME ${test_name} COMMAND ${ARGS_EXECUTABLE})

  # Default properties
  set_target_properties(
    ${ARGS_EXECUTABLE}
    PROPERTIES OUTPUT_NAME ${ARGS_EXECUTABLE}
    COMPILE_OPTIONS "${JCM_DEFAULT_COMPILE_OPTIONS}"
    LINK_LIBRARIES "${ARGS_LIBS}")
endfunction()
