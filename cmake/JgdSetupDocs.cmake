include(JgdParseArguments)
include(JgdValidateArguments)

#
# Enables documentation generation for the current project by providing an
# option, BUILD_DOCS, to enable/disable generation, and adds the 'docs'
# directory to the project. By default, BUILD_DOCS=OFF
#
function(jgd_setup_docs)
  jgd_parse_arguments(ARGUMENTS "${ARGN}")
  jgd_validate_arguments()

  # Setup Documentation Generation
  option(BUILD_DOCS "Build documentation" OFF)
  if(BUILD_DOCS)
    if(IS_DIRECTORY docs)
      add_subdirectory(docs)
    else()
      message(
        SEND_ERROR
          "BUILD_DOCS option specified as true, but docs directory doesn't "
          "exist. Cannot build docs.")
    endif()
  endif()

endfunction()
