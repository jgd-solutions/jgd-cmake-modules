include(JgdParseArguments)

macro(jgd_check_set variable value)
  jgd_parse_arguments(MULTI_VALUE_KEYWORDS "CHECK" ARGUMENTS "${ARGN}")

  set(check NOT DEFINED)
  if(ARGS_CHECK)
    set(check ${ARGS_CHECK})
  endif()

  if(${check} ${variable})
    set(${variable} "${value}")
  endif()
endmacro()
