include_guard()

include(JgdParseArguments)

function(jgd_project_prefix_name)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "OUT_VAR" REQUIRED_ALL "OUT_VAR"
                      ARGUMENTS "${ARGN}")

  set(prefix_temp)
  string(TOUPPER ${PROJECT_NAME} prefix_temp)
  string(REPLACE "-" "_" ${prefix_temp} project_prefix)

endfunction()
