include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdStandardDirs.cmake)

#
# Enables testing for the current project by including CTest CMake script, which
# provides the BUILD_TESTING option, and adds the 'tests' subdirectory to the
# project.
#
macro(JGD_SETUP_TESTS)
  jgd_parse_arguments(ARGUMENTS "${ARGN}")
  jgd_validate_arguments()

  include(CTest)
  if(BUILD_TESTING)
    if(IS_DIRECTORY "${JGD_PROJECT_TESTS_DIR}")
      add_subdirectory("${JGD_PROJECT_TESTS_DIR}")
    else()
      message(
        SEND_ERROR
          "BUILD_TESTING option is valid, but tests directory "
          "(${JGD_PROJECT_TESTS_DIR}) doesn't exist. Cannot build tests.")
    endif()
  endif()

endmacro()
