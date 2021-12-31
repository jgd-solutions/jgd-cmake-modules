include(JgdParseArguments)
include(JgdValidateArguments)

#
# Enables testing for the current project by providing an option to
# enable/disable tests, BUILD_TESTS, includes CTest CMake script, and adds the
# 'tests' subdirectory to the project. CTests' CMake module provides a
# BUILD_TESTING option, which is overriden by the BUILD_TESTS option intoduced
# in by this function. By default, BUILD_TESTS=OFF.
#
macro(JGD_SETUP_TESTS)
  jgd_parse_arguments(ARGUMENTS "${ARGN}")
  jgd_validate_arguments()

  # Setup Testing
  include(CTest)
  if(BUILD_TESTING)
    set(tests_dir "${PROJECT_SOURCE_DIR}/tests")
    if(IS_DIRECTORY ${tests_dir})
      add_subdirectory(${tests_dir})
    else()
      message(
        SEND_ERROR "BUILD_TESTS option specified as true, but tests directory "
                   "(${tests_dir}) doesn't exist. Cannot build tests.")
    endif()
  endif()

endmacro()
