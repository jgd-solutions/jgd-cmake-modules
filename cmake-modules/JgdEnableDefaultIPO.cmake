include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)

#
# If IPO is supported, enable Interprocedural Linker Optimizations for  all
# targets of a project, by setting the project wide
# CMAKE_INTERPROCEDURAL_OPTIMIZATION variable to TRUE. Each target's
# INTERPROCEDURAL_OPTIMIZATION property is defaulted to the value of
# CMAKE_INTERPROCEDURAL_OPTIMIZATION. Calling this function will thereby set
# each target's default INTERPROCEDURAL_OPTIMIZATION value to TRUE, but they can
# be overridden on a target-by-target basis.
#
function(jgd_enable_default_ipo)
  jgd_parse_arguments(ARGUMENTS "${ARGN}")
  jgd_validate_arguments()

  # Enable IPO, if it's supported
  include(CheckIPOSupported)
  check_ipo_supported(RESULT ipo_supported OUTPUT err_msg)
  if(ipo_supported)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION
        TRUE
        PARENT_SCOPE)
  else()
    message(
      WARNING
        "Interprocedural linker optimization is not supported: ${err_msg}\n"
        "Continuing without it.")
  endif()
endfunction()
