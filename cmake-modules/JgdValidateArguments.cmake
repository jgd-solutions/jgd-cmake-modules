include_guard()

include(CMakeParseArguments)

#
# Validates the arguments of the calling function/macro that were parsed by a
# call to cmake_parse_arguments(PREFIX ...).
#
# Arguments:
#
# KEYWORDS: multi-value arg; the keywords of the calling function/macro's
# arguments to individually validate, where all must be present. Should include
# a desired subset of one-value and multi-value keywords of the calling
# function/macro's arguments.
#
# ONE_OF_KEYWORDS: multi-value arg; the keywords of the calling function/macro's
# arguments to individually validate, where at least one must be present. Should
# include a desired subset of one-value and multi-value keywords of the calling
# function/macro's arguments.
#
# PREFIX: one value arg; the keyword prefix applied to each of the provided
# KEYWORDS by the call to cmake_parse_arguments. Defaults to "ARGS".
#
# WITHOUT_MISSING_VALUES_CHECK: option; when defined, arguments with missing
# values will be ignored
#
# WITHOUT_UNPARSED_CHECK: option; when defined, unparsed arguments (those that
# were provided but were not expected by the function) will be ignored
#
function(jgd_validate_arguments)
  # Arguments of jgd_validate_arguments
  set(options WITHOUT_MISSING_VALUES_CHECK WITHOUT_UNPARSED_CHECK)
  set(one_value_keywords PREFIX)
  set(multi_value_keywords KEYWORDS ONE_OF_KEYWORDS)
  cmake_parse_arguments(INS "${options}" "${oneValueKeywords}"
                        "${multiValueArgs}" ${ARGN})

  # Argument Validation of jgd_validate_arguments
  if(NOT DEFINED INS_KEYWORDS
     AND DEFINED WITHOUT_MISSING_VALUES_CHECK
     AND DEFINED WITHOUT_UNPARSED_CHECK)
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} was called with all "
                        "available validations disabled.")
  endif()

  # Defaults
  if(NOT DEFINED INS_PREFIX)
    # cmake-lint: disable=C0103
    set(INS_PREFIX "ARGS")
  endif()

  # Argument Validation for the caller's arguments

  # keywords that all must be present
  foreach(keyword ${INS_KEYWORDS})
    set(parsed_var ${INS_PREFIX}_${keyword})
    if(NOT DEFINED ${parsed_var})
      message(FATAL_ERROR "${keyword} was not provided or may be missing "
                          "its value(s).")
    endif()
  endforeach()

  # keywords that at least one must be present
  set(at_least_one_defined FALSE)
  foreach(keyword ${INS_ONE_OF_KEYWORDS})
    set(parsed_var ${INS_PREFIX}_${keyword})
    if(parsed_var)
      set(at_least_one_defined TRUE)
      break()
    endif()
  endforeach()

  if(INS_ONE_OF_KEYWORDS AND NOT at_least_one_defined)
    message(
      FATAL_ERROR
        "None of the following keywords were provided or may be missing their "
        "values: ${INS_ONE_OF_KEYWORDS}")
  endif()

  # argument format validations
  if(NOT DEFINED WITHOUT_MISSING_VALUES_CHECK
     AND DEFINED ${INS_PREFIX}_KEYWORDS_MISSING_VALUES)
    message(FATAL_ERROR "Keywords provided without any values: "
                        "${${INS_PREFIX}_KEYWORDS_MISSING_VALUES}")
  endif()

  if(NOT DEFINED WITHOUT_UNPARSED_CHECK AND DEFINED
                                            ${INS_PREFIX}_UNPARSED_ARGUMENTS)
    message(WARNING "Unparsed arguments provided: "
                    "${${INS_PREFIX}_UNPARSED_ARGUMENTS}")
  endif()
endfunction()
