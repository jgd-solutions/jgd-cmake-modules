include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdDefaultTargetProps)
include(JgdFileNaming)

#
# A convenience function to create an executable and add it as a test in one
# command.  An executable called EXECUTABLE will be created from the sources
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
# executable. Commonly the library under test and testing framework. Optional.
#
function(jgd_add_default_executable)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "EXECUTABLE" MULTI_VALUE_KEYWORDS
                      "SOURCES" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "EXECUTABLE;SOURCES")

  # Verify source naming
  foreach(source ${ARGS_SOURCES})
    set(regex "${JGD_HEADER_REGEX}|${JGD_SOURCE_REGEX}")
    string(REGEX MATCH "${regex}" matched "${source}")
    if(NOT matched)
      message(FATAL_ERROR "Provided source file, ${source}, does not match the"
                          "regex for executable sources, ${regex}.")
    endif()
  endforeach()

  # Executable with default properties
  add_executable("${ARGS_EXECUTABLE}" "${ARGS_SOURCES}")
  target_compile_options("${ARGS_EXECUTABLE}"
                         PRIVATE ${JGD_DEFAULT_COMPILE_OPTIONS})
  jgd_default_include_dir(BUILD_INTERFACE OUT_VAR include_dir)
  target_include_directories("${ARGS_EXECUTABLE}" PRIVATE ${include_dir})
endfunction()
