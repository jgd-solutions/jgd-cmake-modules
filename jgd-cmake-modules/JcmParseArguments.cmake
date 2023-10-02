include_guard()

#[=======================================================================[.rst:

JcmParseArguments
-----------------

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
       [ONE_VALUE_KEYWORDS <keyword>...]
       [MULTI_VALUE_KEYWORDS <keyword>...]>
      [REQUIRES_ALL <keyword>...]
      [REQUIRES_ANY <keyword>...]
      [MUTUALLY_EXCLUSIVE <keyword>..]
      [MUTUALLY_EXCLUSIVE_<n> <keyword>..]
      ARGUMENTS <arg>...
    )


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

:cmake:variable:`MUTUALLY_EXCLUSIVE`
  A list of keywords from any of the above keyword lists that must one one keyword present. If
  :cmake:variable:`ARGUMENTS` includes more than one of the keywords listed here, parsing will emit
  an error.

:cmake:variable:`MUTUALLY_EXCLUSIVE_<n>`
  Where *n* is an integer in the range [1,3], these three arguments provide the exact same
  functionality as :cmake:variable:`MUTUALLY_EXCLUSIVE`, but through separate variables so multiple
  exclusivity constraints can be provided simultaneously. Each constraint is independently verified.

  A list of keywords from any of the above keyword lists that must one one keyword present. If
  :cmake:variable:`ARGUMENTS` includes more than one of the keywords listed here, parsing will emit
  an error.

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

    foreach(input "${ARGS_INPUT}")
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

  # Error, USE_PERL_REGEX and USE_EXTENDED provided
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
    [[ARGUMENTS;OPTIONS;ONE_VALUE_KEYWORDS;MULTI_VALUE_KEYWORDS;REQUIRES_ALL;REQUIRES_ANY;MUTUALLY_EXCLUSIVE;MUTUALLY_EXCLUSIVE_1;MUTUALLY_EXCLUSIVE_2;MUTUALLY_EXCLUSIVE_3]]
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

  foreach(req_keyword IN LISTS INS_REQUIRES_ALL INS_REQUIRES_ANY)
    list(FIND parsed_keywords ${req_keyword} idx)
    if(idx EQUAL -1)
      message(
        FATAL_ERROR
        "The required keyword ${req_keyword} is not in the list of function "
        "keywords ${parsed_keywords}. This keyword cannot be required if it "
        "is not parsed by the function.")
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
  if(INS_REQUIRES_ANY)
    set(at_least_one_defined FALSE)
    foreach(keyword IN LISTS INS_REQUIRES_ANY)
      if(DEFINED ${INS_PREFIX}_${keyword})
        set(at_least_one_defined TRUE)
        break()
      endif()
    endforeach()

    if(NOT at_least_one_defined)
      message(
        FATAL_ERROR
        "None of the following keywords were provided or may be missing their values: ${INS_REQUIRES_ANY}")
    endif()
    unset(at_least_one_defined)
  endif()


  # validate keywords that are mutually exclusive
  unset(first_keyword)
  unset(second_keyword)

  foreach(keyword IN LISTS
    INS_MUTUALLY_EXCLUSIVE
    INS_MUTUALLY_EXCLUSIVE_1
    INS_MUTUALLY_EXCLUSIVE_2
    INS_MUTUALLY_EXCLUSIVE_3)

    # foreach IN LISTS won't execute body if list isn't defined :)
    list(FIND INS_ARGUMENTS ${keyword} idx)
    if(NOT idx EQUAL -1)
      if(DEFINED first_keyword)
        set(second_keyword ${keyword})
        break()
      else()
        set(first_keyword ${keyword})
      endif()
    endif()
  endforeach()

  if(DEFINED second_keyword)
    message(FATAL_ERROR "The keywords ${first_keyword} and ${second_keyword} were both defined but are part of the "
      "mutually exclusive list of function arguments: ${INS_MUTUALLY_EXCLUSIVE}")
  endif()

  unset(idx)
  unset(second_keyword)
  unset(first_keyword)

  # validate caller's argument format
  if(NOT INS_WITHOUT_MISSING_VALUES_CHECK AND ${INS_PREFIX}_KEYWORDS_MISSING_VALUES)
    message(FATAL_ERROR "Keywords provided without any values: "
      "${${INS_PREFIX}_KEYWORDS_MISSING_VALUES}")
  endif()

  if(NOT INS_WITHOUT_UNPARSED_CHECK AND ${INS_PREFIX}_UNPARSED_ARGUMENTS)
    message(WARNING "Unparsed arguments provided: ${${INS_PREFIX}_UNPARSED_ARGUMENTS} ")
  endif()
endmacro()
