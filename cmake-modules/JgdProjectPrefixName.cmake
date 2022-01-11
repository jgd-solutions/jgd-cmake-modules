include_guard()

include(JgdParseArguments)

function(jgd_project_prefix_name)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "OUT_VAR" ARGUMENTS "${ARGN}")

endfunction()
