include_guard()

include(JcmParseArguments)

#
# Separates the INPUT into two groups: OUT_MATCHED, if the element matches the
# provided REGEX and OUT_UNMATCHED, otherwise. Before matching, the elements can
# optionally be transformed by the selected TRANSFORM before being matched.
# Nevertheless, INPUT is not modified, and the results in the out-variables
# will always be identical to those provided via INPUT.
#
# Arguments:
#
# INPUT: multi-value arg; list of values to split based on the provided REGEX.
#
# REGEX: one-value arg; the regex to match each INPUT element against.
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
    MULTI_VALUE_KEYWORDS "INPUT"
    REQUIRES_ALL "REGEX;INPUT"
    REQUIRES_ANY "OUT_MATCHED;OUT_UNMATCHED"
    ARGUMENTS "${ARGN}")

  set(supported_transforms "FILENAME")
  if(DEFINED ARGS_TRANSFORM AND NOT ARGS_TRANSFORM MATCHES "${supported_transforms}")
    message(FATAL_ERROR "The TRANSFORM of ${ARGS_TRANSFORM} is not supported. "
                        "It must be one of ${supported_transforms}.")
  endif()

  # Split input into two lists
  set(matched_elements)
  set(unmatched_elements)
  foreach(element ${ARGS_INPUT})
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


function(jcm_transform_list)
  # Argument parsing, allowing value to INPUT to be empty
  jcm_parse_arguments(
    WITHOUT_MISSING_VALUES_CHECK
    OPTIONS "ABSOLUTE_PATH"
    ONE_VALUE_KEYWORDS "BASE;OUT_VAR"
    MULTI_VALUE_KEYWORDS "INPUT"
    REQUIRES_ALL "OUT_VAR"
    REQUIRES_ANY "ABSOLUTE_PATH"
    MUTUALLY_EXCLUSIVE "ABSOLUTE_PATH"
    ARGUMENTS "${ARGN}"
  )

  # check for missing values on other variables, besides INPUT
  if(ARGS_KEYWORDS_MISSING_VALUES)
    set(missing_required_keywords "${ARGS_KEYWORDS_MISSING_VAL}")
    list(FILTER missing_required_keywords EXCLUDE REGEX "INPUT")
    if(missing_required_keywords)
      message(FATAL_ERROR "Keywords provided without any values: ${missing_required_keywords}")
    endif()
  endif()

  # Set transformation code based on selected transformation argument
  if(ARGS_ABSOLUTE_PATH)
    if(NOT DEFINED ARGS_BASE)
      set(absolute_base_path "${CMAKE_CURRENT_SOURCE_DIR}")
    else()
      set(absolute_base_path "${ARGS_BASE}")
    endif()

    set(selected_transformation [=[
      if(IS_ABSOLUTE "${input}")
        set(transformed_result "${input}")
      else()
        set(transformed_result "${absolute_base_path}/${input}")
      endif()
    ]=])
  endif()

  # Transform list
  set(transformed_results)
  foreach(input IN LISTS ARGS_INPUT)
    set(transformed_result)
    cmake_language(EVAL CODE "${selected_transformation}")
    list(APPEND transformed_results "${transformed_result}")
  endforeach()

  set(${ARGS_OUT_VAR} "${transformed_results}" PARENT_SCOPE)
endfunction()

function(jcm_regex_find_list)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "OUT_IDX;REGEX"
    MULTI_VALUE_KEYWORDS "INPUT"
    REQUIRES_ALL "OUT_IDX;REGEX;INPUT"
    ARGUMENTS "${ARGN}"
  )

  set(found_idx -1)
  set(current_idx 0)

  foreach(input ${ARGS_INPUT})
    if(input MATCHES "${ARGS_REGEX}")
      set(found_idx ${current_idx})
      break()
    endif()

    math(EXPR current_idx "${current_idx}+1")
  endforeach()

  set(${ARGS_OUT_IDX} "${found_idx}" PARENT_SCOPE)
endfunction()
