include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdDefaultTargetProps)

#
# A convenience function to create an executable and add it as a test in one
# command.  An executable with name EXECUTABLE will be created from the sources
# provided to SOURCES. This executable will then be registered as a test with
# name NAME, or EXECUTABLE, if NAME is not provided.
#
# Arguments:
#
# EXECUTABLE: one value arg; the name of the test executable to generate.
#
# NAME: one value arg; the name of the test to register with CTest. Will be set
# to EXECUTABLE, if not provided.
#
# SOURCES: multi value arg; the sources to create EXECUTABLE from.
#
# LIBS: multi value arg; list of libraries to privately link against the test
# executable. Commonly the library under test. Optional.
#
function(jgd_add_test_executable)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "EXECUTABLE;NAME" MULTI_VALUE_KEYWORDS
                      "SOURCES;LIBS" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "EXECUTABLE;SOURCES")

  set(test_name "${ARGS_NAME}")
  if(NOT ARGS_NAME)
    set(test_name "${ARGS_EXECUTABLE}")
  endif()

  add_executable("${ARGS_EXECUTABLE}" "${ARGS_SOURCES}")
  add_test(NAME ${test_name} COMMAND "${ARGS_EXECUTABLE}")

  if(ARGS_LIBS)
    target_link_libraries("${ARGS_EXECUTABLE}" PRIVATE "${ARGS_LIBS}")
  endif()
endfunction()
