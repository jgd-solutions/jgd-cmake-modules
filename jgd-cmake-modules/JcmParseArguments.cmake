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
named arguments, consistent support for empty values, and handles argument validation. Errors will
result in fatal errors being emitted.

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

:cmake:variable:`ALLOW_EMPTY_MULTI_VALUE`
  Normally, empty multi-value arguments are rejected in the same way as the keyword being omitted.
  When provided, this flag will cause multi-value arguments that are provided as empty or are
  missing values to be defined as empty values.

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
      # USE_PERL_REGEX was given to separate_list()
      # example usage of option
    else()
      # USE_PERL_REGEX was NOT given to separate_list()
    endif()

    if(DEFINED ARGS_OUT_MATCHED)
      # OUT_MATCHED was given to separate_list()
      # example usage of one-value argument
    endif()

    if(DEFINED ARGS_INPUT)
      # non-empty INPUT was given to separate_list()
      foreach(input IN LISTS ARGS_INPUT)
        # example usage of multi-value argument
      endforeach()
    endif()

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
    "WITHOUT_MISSING_VALUES_CHECK;WITHOUT_UNPARSED_CHECK;ALLOW_EMPTY_MULTI_VALUE"
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
    message(WARNING "Unrecognized arguments provided to jcm_parse_arguments: "
      "${INS_UNPARSED_ARGUMENTS}")
  endif()

  # ensure combinatorial keywords are a subset of the function's available keywords
  set(parsed_keywords ${INS_ONE_VALUE_KEYWORDS} ${INS_MULTI_VALUE_KEYWORDS})
  foreach(keyword IN LISTS INS_REQUIRES_ALL)
    if("${keyword}" IN_LIST INS_OPTIONS)
      message(FATAL_ERROR
        "The required keyword '${keyword}' names a function option, which cannot be always "
        "required, as this would render the option useless")
    elseif(NOT "${keyword}" IN_LIST parsed_keywords)
      message(FATAL_ERROR
        "The required keyword '${keyword}' is not a function keyword; one of '${parsed_keywords}'")
    endif()
  endforeach()

  list(APPEND parsed_keywords ${INS_OPTIONS})
  foreach(comb_list IN ITEMS
      INS_REQUIRES_ANY INS_REQUIRES_ANY_1 INS_REQUIRES_ANY_2 INS_REQUIRES_ANY_3
      INS_MUTUALLY_EXCLUSIVE INS_MUTUALLY_EXCLUSIVE_1 INS_MUTUALLY_EXCLUSIVE_2 INS_MUTUALLY_EXCLUSIVE_3
      INS_MUTUALLY_INCLUSIVE INS_MUTUALLY_INCLUSIVE_1 INS_MUTUALLY_INCLUSIVE_2 INS_MUTUALLY_INCLUSIVE_3)
    foreach(keyword IN LISTS ${comb_list})
      if(NOT "${keyword}" IN_LIST parsed_keywords)
        message(FATAL_ERROR
          "The keyword '${keyword}' provided to ${comb_list} is not a function keyword; one of "
          "'${parsed_keywords}'")
      endif()
    endforeach()
  endforeach()

  unset(parsed_keywords)

  if(NOT DEFINED INS_PREFIX)
    set(INS_PREFIX "ARGS")
  endif()

  # == Parse and Validate Caller's Arguments ==

  # parse the caller's arguments
  cmake_parse_arguments(${INS_PREFIX} "${INS_OPTIONS}" "${INS_ONE_VALUE_KEYWORDS}"
    "${INS_MULTI_VALUE_KEYWORDS}" "${INS_ARGUMENTS}")


  block(SCOPE_FOR VARIABLES)

  if(INS_ALLOW_EMPTY_MULTI_VALUE)
    # cmake_parse_arguments() will not define the argument value when it's empty or completely
    # omitted. Define argument values to empty for every multi-value keyword provided w/o a value
    foreach(keyword IN LISTS ${INS_PREFIX}_KEYWORDS_MISSING_VALUES)
      if(keyword IN_LIST INS_MULTI_VALUE_KEYWORDS)
        set(${INS_PREFIX}_${keyword} "")
        list(REMOVE_ITEM ${INS_PREFIX}_KEYWORDS_MISSING_VALUES ${keyword})
      endif()
    endforeach()
  endif()

  # validate keywords that must all be present
  # note: none of these keywords can be options
  foreach(keyword IN LISTS INS_REQUIRES_ALL)
    if(DEFINED ${INS_PREFIX}_${keyword})
      set(at_least_one_defined TRUE)
      break()
    endif()
  endforeach()

  # validate keywords that must have one present
  # note: for the keywords that are options, they'll always be defined
  foreach(requires_any_arg IN ITEMS
    INS_REQUIRES_ANY INS_REQUIRES_ANY_1 INS_REQUIRES_ANY_2 INS_REQUIRES_ANY_3)
    if(NOT ${requires_any_arg})
      continue()
    endif()

    set(at_least_one_defined FALSE)
    foreach(keyword IN LISTS ${requires_any_arg})
      if(${INS_PREFIX}_${keyword} OR
        (DEFINED ${INS_PREFIX}_${keyword} AND NOT keyword IN_LIST INS_OPTIONS))
        set(at_least_one_defined TRUE)
        break()
      endif()
    endforeach()

    if(NOT at_least_one_defined)
      message(FATAL_ERROR
        "None of the following keywords were provided: '${${requires_any_arg}}'")
    endif()
  endforeach()


  # validate keywords that are mutually exclusive
  foreach(mutex_list IN ITEMS
    INS_MUTUALLY_EXCLUSIVE
    INS_MUTUALLY_EXCLUSIVE_1
    INS_MUTUALLY_EXCLUSIVE_2
    INS_MUTUALLY_EXCLUSIVE_3)

    # foreach IN LISTS won't execute body if list isn't defined :)
    foreach(keyword IN LISTS ${mutex_list})
      if(NOT DEFINED ${INS_PREFIX}_${keyword} OR
          (NOT ${INS_PREFIX}_${keyword} AND keyword IN_LIST INS_OPTIONS))
        continue()
      endif()

      if(DEFINED first_keyword)
        message(FATAL_ERROR
          "The keywords ${first_keyword} and ${keyword} cannot be provided together. Providing "
          "any one of the following keywords precludes providing any other: '${${mutex_list}}'")
        break()
      else()
        set(first_keyword ${keyword})
      endif()
    endforeach()
  endforeach()

  # validate keywords that are mutually inclusive
  foreach(inclusive_list IN ITEMS 
    INS_MUTUALLY_INCLUSIVE
    INS_MUTUALLY_INCLUSIVE_1
    INS_MUTUALLY_INCLUSIVE_2
    INS_MUTUALLY_INCLUSIVE_3)

    set(missing_keywords)
    foreach(keyword IN LISTS ${inclusive_list})
      if(NOT DEFINED ${INS_PREFIX}_${keyword} OR
          (NOT ${INS_PREFIX}_${keyword} AND keyword IN_LIST INS_OPTIONS))
        list(APPEND missing_keywords ${keyword})
      endif()
    endforeach()

    list(LENGTH missing_keywords num_missing)
    list(LENGTH ${inclusive_list} inclusive_size)
    if(NOT num_missing EQUAL 0 AND NOT num_missing EQUAL inclusive_size)
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

  endblock()
endmacro()
