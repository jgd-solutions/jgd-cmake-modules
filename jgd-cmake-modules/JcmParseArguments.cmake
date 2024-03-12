include_guard()

#[=======================================================================[.rst:

JcmParseArguments
-----------------

:github:`JcmParseArguments`

#]=======================================================================]

include(CMakeParseArguments)

#[=======================================================================[.rst:

jcm_parse_arguments
^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_parse_arguments

  .. code-block:: cmake

    jcm_parse_arguments(
      [WITHOUT_MISSING_VALUES_CHECK]
      [WITHOUT_UNPARSED_CHECK]
      [PREFIX <prefix>]
      <[OPTIONS <keyword>...]
       [ONE_VALUE_KEYWORDS <keyword>..]
       [MULTI_VALUE_KEYWORDS <keyword>...] >
      [REQUIRES_ALL <keyword>...]
      [REQUIRES_ANY <keyword>...]
      [REQUIRES_ANY_<n> <keyword>...]
      [MUTUALLY_EXCLUSIVE <keyword>..]
      [MUTUALLY_EXCLUSIVE_<n> <keyword>..]
      [MUTUALLY_INCLUSIVE <keyword>..]
      [MUTUALLY_INCLUSIVE_<n> <keyword>..]
      ARGUMENTS <arg>...)


A wrapper around CMake's :cmake:command:`cmake_parse_arguments` that provides sensible defaults,
named arguments, and handles argument validation. Errors will result in fatal errors being emitted.

Parameters
##########

Options
~~~~~~~

:cmake:variable:`WITHOUT_MISSING_VALUES_CHECK`
  When provided, this macro will *not* check for keywords with missing values in
  :cmake:variable:`ARGUMENTS`

:cmake:variable:`WITHOUT_UNPARSED_CHECK`
  When provided, this macro will *not* check for unparsed keywords in :cmake:variable:`ARGUMENTS`.
  That is keywords that were provided but not included in the following lists of keywords.

One Value
~~~~~~~~~

:cmake:variable:`PREFIX`
  The prefix for result variables from :cmake:command:`cmake_parse_arguments`, which includes parsed
  arguments. Default is "ARGS", so parsed arguments will begin with "ARGS\_".

Multi Value
~~~~~~~~~~~

:cmake:variable:`OPTIONS`
  A list of keywords for arguments that operate as flags. Either they are provided, or they aren't,
  but don't accept values. These argument variables will be defined as FALSE if they aren't
  provided. Keyword list.

:cmake:variable:`ONE_VALUE_KEYWORDS`
  A list of keywords for arguments that require a single value. These argument variables will not be
  defined if they aren't provided. Keywords list.

:cmake:variable:`MULTI_VALUE_KEYWORDS`
  A list of keywords for arguments that require one or more values. These argument variables will
  not be defined if they aren't provided. Keyword list.

:cmake:variable:`REQUIRES_ALL`
  A list of keywords from any of the above keyword lists that are mandatory. If
  :cmake:variable:`ARGUMENTS` does not include the keywords listed here, parsing will emit an error.

:cmake:variable:`REQUIRES_ANY`
  A list of keywords from any of the above keyword lists that must have at least one keyword
  present. If :cmake:variable:`ARGUMENTS` does not include at least one of the keywords listed here,
  parsing will emit an error.

:cmake:variable:`REQUIRES_ANY_<n>`
  Where *n* is an integer in the range [1,3], these three parameters provide the exact same
  functionality as :cmake:variable:`REQUIRES_ANY`, but through separate variables so multiple
  independent constraints can be enforced simultaneously. Each constraints is independently
  verified.

:cmake:variable:`MUTUALLY_EXCLUSIVE`
  A list of keywords from any of the above keyword lists that are restricted from being provided
  simultaneously. If :cmake:variable:`ARGUMENTS` includes more than one of the keywords listed 
  here, parsing will emit an error.

:cmake:variable:`MUTUALLY_EXCLUSIVE_<n>`
  Where *n* is an integer in the range [1,3], these three parameters provide the exact same
  functionality as :cmake:variable:`MUTUALLY_EXCLUSIVE`, but through separate variables so multiple
  exclusivity constraints can be enforced simultaneously. Each constraint is independently verified.

:cmake:variable:`MUTUALLY_INCLUSIVE`
  A list of keywords from any of the above keyword lists that must be provided together; the
  presence of any keyword in this list triggers the requirement of every keyword in this list.
  Should :cmake:variable:`ARGUMENTS` include one of the keywords listed here but not all of them, 
  parsing will emit an error.

:cmake:variable:`MUTUALLY_INCLUSIVE_<n>`
  Where *n* is an integer in the range [1,3], these three parameters provide the exact same
  functionality as :cmake:variable:`MUTUALLY_INCLUSIVE`, but through separate variables so multiple
  inclusivity constraints can be enforced simultaneously. Each constraint is independently verified.

Examples
########

.. code-block:: cmake


  function(separate_list)
    jcm_parse_arguments(
      OPTIONS "USE_PERL_REGEX" "USE_EXTENDED"
      ONE_VALUE_KEYWORDS "REGEX;OUT_MATCHED;OUT_MISMATCHED"
      MULTI_VALUE_KEYWORDS "INPUT"
      REQUIRES_ALL "REGEX;INPUT"
      REQUIRES_ANY "OUT_MATCHED;OUT_MISMATCHED"
      MUTUALLY_EXCLUSIVE "USE_PERL_REGEX" "USE_EXTENDED"
      ARGUMENTS "${ARGN}")

    if(ARGS_USE_PERL_REGEX)
      # example usage of option
    endif()

    if(DEFINED ARGS_OUT_MATCHED)
      # example usage of one-value argument
    endif()

    foreach(input IN LISTS ARGS_INPUT)
      # example usage of multi-value argument
    endforeach()

    # ...
  endfunction()

  # Ok
  separate_list(
    INPUT "first" "second" "third"
    REGEX ".*$d"
    OUT_MATCHED ends_with_d)

  # Error, INPUT not provided
  separate_list(
    REGEX ".*$d"
    OUT_MATCHED ends_with_d
    OUT_MISMATCHED doesnt_end_with_d)

  # Error, OUT_MATCHED nor OUT_MISMATCHED provided
  separate_list(
    INPUT "first" "second" "third"
    REGEX ".*$d")

  # Error, USE_PERL_REGEX **and** USE_EXTENDED provided
  separate_list(
    USE_PERL_REGEX
    USE_EXTENDED
    INPUT "first" "second" "third"
    REGEX ".*$d")

#]=======================================================================]
macro(JCM_PARSE_ARGUMENTS)
  # Arguments to jcm_parse_arguments
  cmake_parse_arguments(INS
    # options
    "WITHOUT_MISSING_VALUES_CHECK;WITHOUT_UNPARSED_CHECK"
    # one-value
    "PREFIX"
    # multi-value
    [[ARGUMENTS;OPTIONS;ONE_VALUE_KEYWORDS;MULTI_VALUE_KEYWORDS;REQUIRES_ALL;REQUIRES_ANY;REQUIRES_ANY_1;REQUIRES_ANY_2;REQUIRES_ANY_3;MUTUALLY_EXCLUSIVE;MUTUALLY_EXCLUSIVE_1;MUTUALLY_EXCLUSIVE_2;MUTUALLY_EXCLUSIVE_3;MUTUALLY_INCLUSIVE;MUTUALLY_INCLUSIVE_1;MUTUALLY_INCLUSIVE_2;MUTUALLY_INCLUSIVE_3]]
    # function arguments
    "${ARGN}")


  # == Argument Validation of jcm_parse_arguments ==

  # no missing values or unnecessary keywords when arguments were provided
  if(INS_KEYWORDS_MISSING_VALUES AND DEFINED INS_ARGUMENTS)
    message(FATAL_ERROR "Keywords provided to jcm_parse_arguments without any "
      "values: ${INS_KEYWORDS_MISSING_VALUES}")
  endif()
  if(INS_UNPARSED_ARGUMENTS)
    message(WARNING "Unparsed arguments provided to jcm_parse_arguments: "
      "${INS_UNPARSED_ARGUMENTS}")
  endif()

  # ensure required keywords are a subset of the function's parsed keywords
  set(parsed_keywords ${INS_OPTIONS} ${INS_ONE_VALUE_KEYWORDS} ${INS_MULTI_VALUE_KEYWORDS})

  foreach(req_keyword IN LISTS
    INS_REQUIRES_ALL INS_REQUIRES_ANY INS_REQUIRES_ANY_1 INS_REQUIRES_ANY_2 INS_REQUIRES_ANY_3)
    if(NOT "${req_keyword}" IN_LIST parsed_keywords)
      message(FATAL_ERROR
        "The required keyword '${req_keyword}' is not in the list of function keywords, "
        "'${parsed_keywords}'. This keyword cannot be required if it is not a function parameter")
    endif()
  endforeach()

  unset(parsed_keywords)

  if(NOT DEFINED INS_PREFIX)
    set(INS_PREFIX "ARGS")
  endif()

  # == Parse and Validate Caller's Arguments ==

  # parse the caller's arguments
  cmake_parse_arguments(${INS_PREFIX} "${INS_OPTIONS}" "${INS_ONE_VALUE_KEYWORDS}"
    "${INS_MULTI_VALUE_KEYWORDS}" "${INS_ARGUMENTS}")

  # validate keywords that must all be present
  foreach(keyword ${INS_REQUIRES_ALL})
    if(NOT DEFINED ${INS_PREFIX}_${keyword})
      message(FATAL_ERROR "${keyword} was not provided or may be missing its value(s).")
    endif()
  endforeach()

  # validate keywords that must have one present
  foreach(requires_any_arg IN ITEMS
    INS_REQUIRES_ANY INS_REQUIRES_ANY_1 INS_REQUIRES_ANY_2 INS_REQUIRES_ANY_3)
    if(NOT ${requires_any_arg})
      continue()
    endif()

    set(at_least_one_defined FALSE)
    foreach(param_keyword IN LISTS ${requires_any_arg})
      if(DEFINED ${INS_PREFIX}_${param_keyword})
        set(at_least_one_defined TRUE)
        break()
      endif()
    endforeach()

    if(NOT at_least_one_defined)
      message(FATAL_ERROR
        "None of the following keywords were provided or may be missing their values: "
        "'${${requires_any_arg}}'")
    endif()
    unset(at_least_one_defined)
  endforeach()


  # validate keywords that are mutually exclusive
  foreach(mutex_list IN ITEMS
    INS_MUTUALLY_EXCLUSIVE
    INS_MUTUALLY_EXCLUSIVE_1
    INS_MUTUALLY_EXCLUSIVE_2
    INS_MUTUALLY_EXCLUSIVE_3)

    unset(first_keyword)
    unset(second_keyword)

    # foreach IN LISTS won't execute body if list isn't defined :)
    foreach(keyword IN LISTS ${mutex_list})
      if(NOT "${keyword}" IN_LIST INS_ARGUMENTS)
        continue()
      endif()

      if(DEFINED first_keyword)
        set(second_keyword ${keyword})
        set(violated_mutex_list ${mutex_list})
        break()
      else()
        set(first_keyword ${keyword})
      endif()
    endforeach()
    
    if(DEFINED second_keyword)
      message(FATAL_ERROR
        "The keywords ${first_keyword} and ${second_keyword} cannot be provided togehter. They're "
        "part of the mutually exclusive list of function arguments, '${${mutex_list}}'. Providing "
        "any one of these precludes providing any other.")
    endif()
  endforeach()


  unset(first_keyword)
  unset(second_keyword)

  # validate keywords that are mutually inclusive
  foreach(inclusive_list IN ITEMS 
    INS_MUTUALLY_INCLUSIVE
    INS_MUTUALLY_INCLUSIVE_1
    INS_MUTUALLY_INCLUSIVE_2
    INS_MUTUALLY_INCLUSIVE_3)

    if(NOT DEFINED ${inclusive_list})
      continue()
    endif()

    set(missing_keywords "${${inclusive_list}}")
    list(REMOVE_ITEM missing_keywords ${INS_ARGUMENTS}) 
    if(missing_keywords STREQUAL "${${inclusive_list}}")
      # all keywords in inclusivity list are missing: condition satisfied
      continue()
    endif()
    if(missing_keywords)
      message(FATAL_ERROR
        "The following keywords are missing: '${missing_keywords}'. They're part of the mutually "
        "inclusive list of function arguments, '${${inclusive_list}}'. Providing any one of "
        "these requires providing all of them.")
    endif()
  endforeach()

  # validate caller's argument format
  if(NOT INS_WITHOUT_MISSING_VALUES_CHECK AND ${INS_PREFIX}_KEYWORDS_MISSING_VALUES)
    message(FATAL_ERROR "Keywords provided without any values: "
      "${${INS_PREFIX}_KEYWORDS_MISSING_VALUES}")
  endif()

  if(NOT INS_WITHOUT_UNPARSED_CHECK AND ${INS_PREFIX}_UNPARSED_ARGUMENTS)
    message(WARNING "Unparsed arguments provided: ${${INS_PREFIX}_UNPARSED_ARGUMENTS} ")
  endif()
endmacro()
