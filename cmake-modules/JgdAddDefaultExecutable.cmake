include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdDefaultTargetProps)
include(JgdFileNaming)

#
# A convenience function to create an executable with default properties defined
# in JgdDefaultTargetProps. An executable called PROJECT_NAME or EXECUTABLE, if
# provided, will be created from the sources provided to SOURCES.
#
# Arguments:
#
# EXECUTABLE: one value arg; the name of the executable to generate. Optional -
# PROJECT_NAME will be used, if not provided.
#
# SOURCES: multi value arg; the sources to create EXECUTABLE from.
#
function(jgd_add_default_executable)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "EXECUTABLE" MULTI_VALUE_KEYWORDS
                      "SOURCES" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "SOURCES")
  set(executable "${PROJECT_NAME}")
  if(ARGS_EXECUTABLE)
    set(executable "${ARGS_EXECUTABLE}")
  endif()

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
  jgd_default_include_dirs(TARGET ${executable} BUILD_INTERFACE OUT_VAR
                           include_dirs)
  target_include_directories("${ARGS_EXECUTABLE}" PRIVATE "${include_dirs}")
endfunction()
