include_guard()

include(JcmParseArguments)

#[=======================================================================[.rst:

JcmListTransformations
----------------------

#]=======================================================================]

#[=======================================================================[.rst:

jcm_separate_list
^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_separate_list

  .. code-block:: cmake

    jcm_separate_list(
      REGEX <regex>
      INPUT <item>...
      [TRANSFORM <transform>]
      <[OUT_MATCHED <out-var>]
       [OUT_MISMATCHED <out-var>]>
    )

Separates the :cmake:variable:`INPUT` into two groups: :cmake:variable:`OUT_MATCHED`, if the element
matches the provided :cmake:variable:`REGEX`, and :cmake:variable:`OUT_MISMATCHED`, otherwise.
Before matching, the elements can optionally be transformed by the selected
:cmake:variable:`TRANSFORM` before being matched. Nevertheless, :cmake:variable:`INPUT` is not
modified, and the results in the out-variables are identical to those provided via INPUT.

Parameters
##########

One Value
~~~~~~~~~

:cmake:variable:`REGEX`
  The regular expression used to separate the input elements.

:cmake:variable:`OUT_MATCHED`
  The variable named will be set to a list of elements from :cmake:variable:`INPUT` that matched
  :cmake:variable:`REGEX`

:cmake:variable:`OUT_MISMATCHED`
  The variable named will be set to a list of elements from :cmake:variable:`INPUT` that did *not*
  match :cmake:variable:`REGEX`

:cmake:variable:`TRANSFORM`
  A transformation to apply to the input before matching. The outputs will not contain this
  transformation. Currently, only "FILENAME" is supported.

Multi Value
~~~~~~~~~~~

:cmake:variable:`INPUT`
  List of elements to split based on :cmake:variable:`REGEX`.

Examples
########

.. code-block:: cmake

  jcm_separate_list(
    REGEX "${JCM_HEADER_REGEX}"
    TRANSFORM "FILENAME"
    OUT_MISMATCHED improperly_named
    INPUT
      "${CMAKE_CURRENT_SOURCE_DIR}/thing.hpp"
      "${CMAKE_CURRENT_SOURCE_DIR}/thINg.hxx"
  )

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_separate_list)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "REGEX;OUT_MATCHED;OUT_MISMATCHED;TRANSFORM"
    MULTI_VALUE_KEYWORDS "INPUT"
    REQUIRES_ALL "REGEX;INPUT"
    REQUIRES_ANY "OUT_MATCHED;OUT_MISMATCHED"
    ARGUMENTS "${ARGN}")

  set(supported_transforms "FILENAME")
  if(DEFINED ARGS_TRANSFORM AND NOT ARGS_TRANSFORM MATCHES "${supported_transforms}")
    message(FATAL_ERROR "The TRANSFORM of ${ARGS_TRANSFORM} is not supported. "
      "It must be one of ${supported_transforms}.")
  endif()

  # Split input into two lists
  set(matched_elements)
  set(mismatched_elements)
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
      list(APPEND mismatched_elements "${element}")
    endif()
  endforeach()

  # Set out variables
  set(${ARGS_OUT_MATCHED} "${matched_elements}" PARENT_SCOPE)
  set(${ARGS_OUT_MISMATCHED} "${mismatched_elements}" PARENT_SCOPE)
endfunction()


#[=======================================================================[.rst:

jcm_transform_list
^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_transform_list

  .. code-block:: cmake

    jcm_transform_list(
      <ABSOLUTE_PATH [BASE <path>] | NORMALIZE_PATH | PARENT_PATH | FILENAME>
      INPUT <item>...
      OUT_VAR <out-var>)

Transforms the items in :cmake:variable:`INPUT` with the given transformation into the list
specified by :cmake:variable:`OUT_VAR`.

Parameters
##########

Options
~~~~~~~

:cmake:variable:`ABSOLUTE_PATH`
  A transformation that treats each input item as a path, and converts it to an absolute path,
  relative to :cmake:variable:`CMAKE_CURRENT_SOURCE_DIR` or :cmake:variable:`BASE`, if provided.
  Excludes other transformation options.

:cmake:variable:`NORMALIZE_PATH`
  A transformation that treats each input item as a path, and converts it to a `normalized
  <https://cmake.org/cmake/help/latest/command/cmake_path.html#normalization>`_ (canonical) path.
  Excludes other transformation options.

:cmake:variable:`PARENT_PATH`
  A transformation that treats each input item as a path, and transforms it to its parent path.
  Excludes other transformation options.

:cmake:variable:`FILENAME`
  A transformation that treats each input item as a path, and transform it to its file name; the
  last component in the path. Excludes other transformation options.

One Value
~~~~~~~~~

:cmake:variable:`OUT_VAR`
  The variable named will be set to a list of transformed input elements.

Multi Value
~~~~~~~~~~~

:cmake:variable:`INPUT`
  List of elements to transform.

Examples
########

.. code-block:: cmake

  jcm_transform_list(
    ABSOLUTE_PATH
    INPUT image.hpp readers.hpp viewer.hpp
    OUT_VAR absolute_headers)

.. code-block:: cmake

  jcm_transform_list(
    FILENAME
    INPUT libimage/image.hpp libimage/readers.hpp libimage/viewer.hpp
    OUT_VAR header_file_names)

  message(STATUS "${header_file_names} == image.hpp;readers.hpp;viewer.hpp")

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_transform_list)
  # Argument parsing, allowing value to INPUT to be empty
  jcm_parse_arguments(
    WITHOUT_MISSING_VALUES_CHECK
    OPTIONS "ABSOLUTE_PATH" "NORMALIZE_PATH" "PARENT_PATH" "FILENAME"
    ONE_VALUE_KEYWORDS "BASE;OUT_VAR"
    MULTI_VALUE_KEYWORDS "INPUT"
    REQUIRES_ALL "OUT_VAR"
    REQUIRES_ANY "ABSOLUTE_PATH" "NORMALIZE_PATH" "FILENAME"
    MUTUALLY_EXCLUSIVE "ABSOLUTE_PATH" "NORMALIZE_PATH" "PARENT_PATH" "FILENAME"
    ARGUMENTS "${ARGN}")

  # check for missing values on other variables, besides INPUT
  if(ARGS_KEYWORDS_MISSING_VALUES)
    set(missing_required_keywords "${ARGS_KEYWORDS_MISSING_VAL}")
    list(FILTER missing_required_keywords EXCLUDE REGEX "INPUT")
    if(missing_required_keywords)
      message(FATAL_ERROR "Keywords provided without any values: ${missing_required_keywords}")
    endif()
  endif()

  # usage guard
  if(DEFINED ARGS_BASE AND NOT ARGS_ABSOLUTE_PATH)
    message(FATAL_ERROR
      "'BASE' may only be provided to ${CMAKE_CURRENT_FUNCTION} with the 'ABSOLUTE_PATH' transformation")
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
  elseif(ARGS_NORMALIZE_PATH)
    set(selected_transformation [=[
      cmake_path(SET transformed_result NORMALIZE "${input}")
    ]=])
  elseif(ARGS_PARENT_PATH)
    set(selected_transformation [=[
      cmake_path(GET input PARENT_PATH transformed_result)
    ]=])
  elseif(ARGS_FILENAME)
    set(selected_transformation [=[
      cmake_path(GET input FILENAME transformed_result)
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


#[=======================================================================[.rst:

jcm_regex_find_list
^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_regex_find_list

  .. code-block:: cmake

    jcm_regex_find_list(
      [MISMATCH]
      REGEX <regex>
      <[OUT_IDX <out-var>
       [OUT_ELEMENT <out-var>]>
      INPUT <item>...)

Searches :cmake:variable:`INPUT` for an item that either matches or mismatches
(:cmake:variable:`MISMATCH` is provided) the regular expression :cmake:variable:`REGEX`.

Parameters
##########

Options
~~~~~~~

:cmake:variable:`MISMATCH`
  Converts the search to find an element that does *not* match the provided :cmake:variable:`REGEX`
  instead of the default.

One Value
~~~~~~~~~

:cmake:variable:`REGEX`
  A regular expression to match against the items in :cmake:variable:`INPUT`.

:cmake:variable:`OUT_IDX`
  The variable named will be set to the found index or -1 if no element could be found.

:cmake:variable:`OUT_ELEMENT`
  The variable named will be set to the found element or NOTFOUND if no element could be found.

Multi Value
~~~~~~~~~~~

:cmake:variable:`INPUT`
  List of elements to search for a matching item.

Examples
########

.. code-block:: cmake

  file(
    GLOB private_dir_files
    LIST_DIRECTORIES false
    RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}/private"
    "${CMAKE_CURRENT_SOURCE_DIR}/private/*")

  jcm_regex_find_list(
    MISMATCH
    REGEX ".*(${JCM_CXX_HEADER_EXTENSION}|${JCM_CXX_SOURCE_EXTENSION})$"
    OUT_IDX misextensioned_idx
    INPUT "${private_dir_files}")

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_regex_find_list)
  jcm_parse_arguments(
    OPTIONS "MISMATCH"
    ONE_VALUE_KEYWORDS "OUT_IDX;OUT_ELEMENT;REGEX"
    MULTI_VALUE_KEYWORDS "INPUT"
    REQUIRES_ANY "OUT_IDX" "OUT_ELEMENT"
    REQUIRES_ALL "REGEX" "INPUT"
    ARGUMENTS "${ARGN}")

  if(ARGS_MISMATCH)
    set(mismatch_not NOT)
  else()
    unset(mismatch_not)
  endif()

  set(found_idx -1)
  set(current_idx 0)
  set(found_element NOTFOUND)

  foreach(input ${ARGS_INPUT})
    if(${mismatch_not} input MATCHES "${ARGS_REGEX}")
      set(found_idx ${current_idx})
      list(GET ARGS_INPUT ${found_idx} found_element)
      break()
    endif()

    math(EXPR current_idx "${current_idx}+1")
  endforeach()

  # Result variables
  if(DEFINED ARGS_OUT_IDX)
    set(${ARGS_OUT_IDX} "${found_idx}" PARENT_SCOPE)
  endif()

  if(DEFINED ARGS_OUT_VALUE)
    set(${ARGS_OUT_ELEMENT} "${found_element}" PARENT_SCOPE)
  endif()
endfunction()
