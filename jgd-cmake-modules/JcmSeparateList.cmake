include_guard()

include(JcmParseArguments)

#
# Separates the IN_LIST into two groups: OUT_MATCHED, if the element matches the
# provided REGEX and OUT_UNMATCHED, otherwise. Before matching, the elements can
# optionally be transformed by the selected TRANSFORM before being matched.
# Nevertheless, IN_LIST is not modified, and the results in the out-variables
# will always be identical to those provided via IN_LIST.
#
# Arguments:
#
# IN_LIST: multi-value arg; list of values to split based on the provided REGEX.
#
# REGEX: one-value arg; the regex to match each IN_LIST element against.
#
# TRANSFORM: one-value arg; a transformation to make on each input element
# before matching it against the regex. Must be one of (only one so far):
# "FILENAME". Optional.
#
# OUT_MATCHED: out-value arg; the name of the variable that will store the list
# of matched elements. Optional if OUT_UNMATCHED is provided.
#
# OUT_UNMATCHED: out-value arg; the name of the variable that will store the
# list of unmatched elements. Optional if OUT_MATCHED is provided.
#
function(jcm_separate_list)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS
    "REGEX;OUT_MATCHED;OUT_UNMATCHED;TRANSFORM"
    MULTI_VALUE_KEYWORDS "IN_LIST"
    REQUIRES_ALL "REGEX;IN_LIST"
    REQUIRES_ANY "OUT_MATCHED;OUT_UNMATCHED"
    ARGUMENTS "${ARGN}")

  set(supported_transforms "FILENAME")
  if(DEFINED ARGS_TRANSFORM AND NOT ARGS_TRANSFORM MATCHES
                                "${supported_transforms}")
    message(FATAL_ERROR "The TRANSFORM of ${ARGS_TRANSFORM} is not supported. "
                        "It must be one of ${supported_transforms}.")
  endif()

  # Split input into two lists
  set(matched_elements)
  set(unmatched_elements)
  foreach(element ${ARGS_IN_LIST})
    # transform element to be matched
    set(transformed_element "${element}")
    if(ARGS_TRANSFORM STREQUAL "FILENAME")
      cmake_path(GET element FILENAME transformed_element)
    endif()

    # compare element against regex
    string(REGEX MATCH "${ARGS_REGEX}" matched "${transformed_element}")
    if(matched)
      list(APPEND matched_elements "${element}")
    else()
      list(APPEND unmatched_elements "${element}")
    endif()
  endforeach()

  # Set out variables
  set(${ARGS_OUT_MATCHED} "${matched_elements}" PARENT_SCOPE)
  set(${ARGS_OUT_UNMATCHED} "${unmatched_elements}" PARENT_SCOPE)
endfunction()
