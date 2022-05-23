include_guard()

include(CMakeParseArguments)

#
# A wrapper around cmake_parse_arguments that provides a consistent prefix,
# ARGS, to the parsed arguments, and argument validation.
#
# Arguments:
#
# ARGUMENTS: multi-value arg; all the caller's arguments to parse
#
# OPTIONS: multi-value arg; options for the calling function/macro
#
# ONE_VALUE_KEYWORDS: multi-value arg; keywords of one-value arguments of
# calling function/macro
#
# MULTI_VALUE_KEYWORDS: multi-value arg; keywords of multi-value arguments of
# calling function/macro
#
# REQUIRES_ALL: multi-value arg; the keywords of the calling function/macro's
# arguments that must all be provided. A fatal error will be emitted if all of
# these arguments weren't provided. Can include any desired subset of OPTIONS,
# ONE_VALUE_KEYWORDS, and MULTI_VALUE_KEYWORDS.
#
# REQUIRES_ANY: multi-value arg; the keywords of the calling function/macro's
# arguments that must have at least one provided. A fatal error will be emitted
# if none of these arguments were provided. Can include any desired subset of
# OPTIONS, ONE_VALUE_KEYWORDS, and MULTI_VALUE_KEYWORDS.
#
# WITHOUT_MISSING_VALUES_CHECK: option; when defined, arguments with missing
# values will be ignored
#
# WITHOUT_UNPARSED_CHECK: option; when defined, unparsed arguments (those that
# were provided but were not expected by the function) will be ignored
#
macro(JGD_PARSE_ARGUMENTS)
  # Arguments to jgd_parse_arguments
  set(options WITHOUT_MISSING_VALUES_CHECK WITHOUT_UNPARSED_CHECK)
  set(one_value_keywords PREFIX)
  set(multi_value_keywords ARGUMENTS OPTIONS ONE_VALUE_KEYWORDS
    MULTI_VALUE_KEYWORDS REQUIRES_ALL REQUIRES_ANY MUTUALLY_EXCLUSIVE)

  cmake_parse_arguments(INS "${options}" "${one_value_keywords}"
    "${multi_value_keywords}" "${ARGN}")

  unset(options)
  unset(one_value_keywords)
  unset(mulit_one_value_keywords)

  # == Argument Validation of jgd_parse_arguments ==

  # no missing values or unnecessary keywords when arguments were provided
  if (INS_KEYWORDS_MISSING_VALUES AND DEFINED INS_ARGUMENTS)
    message(FATAL_ERROR "Keywords provided to jgd_parse_arguments without any "
      "values: ${INS_KEYWORDS_MISSING_VALUES}")
  endif ()
  if (INS_UNPARSED_ARGUMENTS)
    message(WARNING "Unparsed arguments provided to jgd_parse_arguments: "
      "${INS_UNPARSED_ARGUMENTS}")
  endif ()

  # ensure required keywords are a subset of the function's parsed keywords
  set(parsed_keywords ${INS_OPTIONS} ${INS_ONE_VALUE_KEYWORDS} ${INS_MULTI_VALUE_KEYWORDS})

  foreach (req_keyword ${INS_REQUIRES_ALL} ${INS_REQUIRES_ANY})
    list(FIND parsed_keywords ${req_keyword} idx)
    if (idx EQUAL -1)
      message(
        FATAL_ERROR
        "The required keyword ${req_keyword} is not in the list of function "
        "keywords ${parsed_keywords}. This keyword cannot be required if it "
        "is not parsed by the function.")
    endif ()
  endforeach ()

  unset(parsed_keywords)

  if (NOT DEFINED INS_PREFIX)
    set(INS_PREFIX "ARGS")
  endif ()

  # == Parse and Validate Caller's Arguments ==

  # parse the caller's arguments
  cmake_parse_arguments(${INS_PREFIX} "${INS_OPTIONS}" "${INS_ONE_VALUE_KEYWORDS}"
    "${INS_MULTI_VALUE_KEYWORDS}" "${INS_ARGUMENTS}")

  # validate keywords that must all be present
  foreach (keyword ${INS_REQUIRES_ALL})
    if (NOT DEFINED ${INS_PREFIX}_${keyword})
      message(FATAL_ERROR "${keyword} was not provided or may be missing its value(s).")
    endif ()
  endforeach ()

  # validate keywords that must have one present
  if (INS_REQUIRES_ANY)
    set(at_least_one_defined FALSE)
    foreach (keyword ${INS_REQUIRES_ANY})
      if (DEFINED ${INS_PREFIX}_${keyword})
        set(at_least_one_defined TRUE)
        break()
      endif ()
    endforeach ()

    if (NOT at_least_one_defined)
      message(
        FATAL_ERROR
        "None of the following keywords were provided or may be missing their values: ${INS_REQUIRES_ANY}")
    endif ()
    unset(at_least_one_defined)
  endif ()


  # validate keywords that are mutually exclusive
  unset(first_keyword)
  unset(second_keyword)

  foreach(keyword ${INS_MUTUALLY_EXCLUSIVE})
    list(FIND INS_ARGUMENTS ${keyword} idx)
    if (NOT idx EQUAL -1)
      if (DEFINED first_keyword)
        set(second_keyword ${keyword})
        break()
      else ()
        set(first_keyword ${keyword})
      endif ()
    endif ()
  endforeach()

  if (DEFINED second_keyword)
    message(FATAL_ERROR "The keywords ${first_keyword} and ${second_keyword} were both defined but are part of the "
      "mutually exclusive list of function arguments: ${INS_MUTUALLY_EXCLUSIVE}")
  endif ()

  unset(idx)
  unset(second_keyword)
  unset(first_keyword)

  # validate caller's argument format
  if (NOT INS_WITHOUT_MISSING_VALUES_CHECK AND ${INS_PREFIX}_KEYWORDS_MISSING_VALUES)
    message(FATAL_ERROR "Keywords provided without any values: "
      "${${ARGS}_KEYWORDS_MISSING_VALUES}")
  endif ()

  if (NOT INS_WITHOUT_UNPARSED_CHECK AND ${INS_PREFIX}_UNPARSED_ARGUMENTS)
    message(WARNING "Unparsed arguments provided: ${${ARGS}_UNPARSED_ARGUMENTS} ")
  endif ()
endmacro()
