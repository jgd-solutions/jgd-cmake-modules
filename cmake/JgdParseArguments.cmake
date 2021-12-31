include(CMakeParseArguments)
include(JgdValidateArguments)

#
# Simply a wrapper around cmake_parse_arguments that provides a consistent
# prefix, ARGS, to the parsed arguments.
#
# Arguments:
#
# OPTIONS: multi value arg; options for the calling function/macro
#
# ONE_VALUE_KEYWORDS: multi value arg; keywords of one-value arguments of
# calling function/macro
#
# MULTI_VALUE_KEYWORDS: multi value arg; keywords of multi-value arguments of
# calling function/macro
#
# ARGUMENTS: multi value arg; all arguments of the calling function/macro to
# parse
#
macro(JGD_PARSE_ARGUMENTS)
  # Arguments to jgd_parse_arguments
  set(options)
  set(one_value_keywords)
  set(multi_value_keywords OPTIONS ONE_VALUE_KEYWORDS MULTI_VALUE_KEYWORDS
                           ARGUMENTS)
  cmake_parse_arguments(INS "${options}" "${one_value_keywords}"
                        "${multi_value_keywords}" ${ARGN})

  # Argument Validation of jgd_parse_arguments
  jgd_validate_arguments(KEYWORDS "ARGUMENTS" PREFIX "INS")

  # Parse the caller's arguments
  cmake_parse_arguments(ARGS "${INS_OPTIONS}" "${INS_ONE_VALUE_KEYWORDS}"
                        "${INS_MULTI_VALUE_KEYWORDS}" "${INS_ARGUMENTS}")
endmacro()
