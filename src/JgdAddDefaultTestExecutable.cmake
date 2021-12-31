include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdDefaultTargetProps)
include(JgdAddTestExecutable)

#
# A convenience function to create an executable and add it as a test in one
# command, while also setting default target properties.  An executable with
# name EXECUTABLE will be created from the sources provided to SOURCES. This
# executable will then be registered as a test with name NAME, or EXECUTABLE, if
# NAME is not provided. Default properties will be set for private include
# directories, link libraries, and compile commands, in accordance with the
# defaults in JgdDefaultTargetProps.
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
function(jgd_add_default_test_executable)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "EXECUTABLE;NAME" MULTI_VALUE_KEYWORDS
                      "SOURCES;LIBS" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "EXECUTABLE;SOURCES")

  set(name_keyword "")
  if(ARGS_NAME)
    set(name_keyword "NAME")
  endif()

  set(libs_keyword "")
  if(ARGS_LIBS)
    set(libs_keyword "LIBS")
  endif()

  jgd_add_test_executable(
    EXECUTABLE
    "${ARGS_EXECUTABLE}"
    ${name_keyword}
    "${ARGS_NAME}"
    ${libs_keyword}
    "${ARGS_LIBS}"
    SOURCES
    "${ARGS_SOURCES}")
  target_compile_options("${ARGS_EXECUTABLE}"
                         PRIVATE ${JGD_DEFAULT_COMPILE_OPTIONS})
  target_include_directories("${ARGS_EXECUTABLE}"
                             PRIVATE ${JGD_DEFAULT_INCLUDE_DIRS})
  target_link_libraries("${ARGS_EXECUTABLE}" PRIVATE ${JGD_DEFAULT_TEST_LIB})
endfunction()
