include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdDefaultTargetProps)
include(JgdFileNaming)
include(JgdStandardDirs)

#
# A convenience function to create an executable and add it as a test in one
# command, while also setting default target compile options from
# JgdDefaultTargetProps. An executable with name EXECUTABLE will be created from
# the sources provided to SOURCES. This executable will then be registered as a
# test with name NAME, or EXECUTABLE, if NAME is not provided.
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
function(jgd_add_default_test_executable)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "EXECUTABLE;NAME" MULTI_VALUE_KEYWORDS
                      "SOURCES;LIBS" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "EXECUTABLE;SOURCES")

  # Verify source naming

  set(test_source_regex "${JGD_TEST_SOURCE_REGEX}") # unit tests
  if("${CMAKE_CURRENT_SOURCE_DIR}" MATCHES "^${JGD_PROJECT_TESTS_DIR}")
    set(test_source_regex "${JGD_SOURCE_REGEX}") # other tests & drivers
  endif()

  foreach(source ${ARGS_SOURCES})
    set(regex "${JGD_HEADER_REGEX}|${test_source_regex}")
    string(REGEX MATCH "${regex}" matched "${source}")
    if(NOT matched)
      message(FATAL_ERROR "Provided source file, ${source}, does not match the"
                          "regex for test executable sources, ${regex}.")
    endif()
  endforeach()

  # Default test name
  set(test_name "${ARGS_EXECUTABLE}")
  if(ARGS_NAME)
    set(test_name "${ARGS_NAME}")
  endif()

  # Test executable
  add_executable("${ARGS_EXECUTABLE}" "${ARGS_SOURCES}")
  add_test(NAME "${test_name}" COMMAND "${ARGS_EXECUTABLE}")
  if(ARGS_LIBS)
    target_link_libraries("${ARGS_EXECUTABLE}" PRIVATE "${ARGS_LIBS}")
  endif()

  # Default properties
  target_compile_options("${ARGS_EXECUTABLE}"
                         PRIVATE ${JGD_DEFAULT_COMPILE_OPTIONS})
endfunction()
