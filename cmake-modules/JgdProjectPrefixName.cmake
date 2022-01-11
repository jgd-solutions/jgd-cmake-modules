include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)

function(jgd_project_prefix_name)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "OUT_VAR" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "OUT_VAR")

endfunction()
