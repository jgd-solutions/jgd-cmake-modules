include_guard()

include(JgdParseArguments)
include(JgdDefaultCompileOptions)
include(JgdFileNaming)
include(JgdStandardDirs)

#
# A convenience function to create an executable and add it as a test in one
# command, while also setting default target compile options from
# JgdDefaultCompileOptions. An executable with name EXECUTABLE will be created
# from the sources provided to SOURCES. This executable will then be registered
# as a test with name NAME, or EXECUTABLE, if NAME is not provided. This
# function has no affect if <JGD_PROJECT_PREFIX_NAME>_BUILD_TESTS is not set.
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
function(jgd_add_test_executable)
  jgd_parse_arguments(
    ONE_VALUE_KEYWORDS
    "EXECUTABLE;NAME"
    MULTI_VALUE_KEYWORDS
    "SOURCES;LIBS"
    REQUIRES_ALL
    "EXECUTABLE;SOURCES"
    ARGUMENTS
    "${ARGN}")

  if (NOT ${JGD_PROJECT_PREFIX_NAME}_BUILD_TESTS)
    return()
  endif ()

  # Verify source naming

  if ("${CMAKE_CURRENT_SOURCE_DIR}" MATCHES "^${JGD_PROJECT_TESTS_DIR}")
    set(test_source_regex "${JGD_SOURCE_REGEX}") # other tests & drivers, only
  else ()
    set(test_source_regex "${JGD_TEST_SOURCE_REGEX}") # unit test files, only
  endif ()

  set(regex "${JGD_HEADER_REGEX}|${test_source_regex}")
  foreach (source ${ARGS_SOURCES})
    string(REGEX MATCH "${regex}" matched "${source}")
    if (NOT matched)
      message(FATAL_ERROR "Provided source file, ${source}, does not match the"
        "regex for test executable sources, ${regex}.")
    endif ()
  endforeach ()

  # Default test name
  set(test_name "${ARGS_EXECUTABLE}")
  if (DEFINED ARGS_NAME)
    set(test_name "${ARGS_NAME}")
  endif ()

  # Test executable
  add_executable(${ARGS_EXECUTABLE} "${ARGS_SOURCES}")
  add_test(NAME ${test_name} COMMAND ${ARGS_EXECUTABLE})

  # Default properties
  set_target_properties(
    ${ARGS_EXECUTABLE}
    PROPERTIES OUTPUT_NAME ${ARGS_EXECUTABLE}
    COMPILE_OPTIONS "${JGD_DEFAULT_COMPILE_OPTIONS}"
    LINK_LIBRARIES "${ARGS_LIBS}")
endfunction()
