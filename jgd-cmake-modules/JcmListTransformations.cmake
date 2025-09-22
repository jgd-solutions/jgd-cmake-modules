include_guard()

include(JcmParseArguments)
include(JcmTargetNaming)

#[=======================================================================[.rst:

JcmListTransformations
----------------------

:github:`JcmListTransformations`

#]=======================================================================]

#[=======================================================================[.rst:

jcm_separate_list
^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_separate_list

  .. code-block:: cmake

    jcm_separate_list(
      INPUT [item]...
      <[OUT_MATCHED <out-var>]
       [OUT_MISMATCHED <out-var>] >
      <REGEX <regex> | IS_DIRECTORY | IS_SYMLINK | IS_ABSOLUTE | IS_TARGET | EVAL_TRUE>
      [TRANSFORM <FILENAME|ALIASED_TARGET>])

Separates the elements of list :cmake:variable:`INPUT` into two groups:
:cmake:variable:`OUT_MATCHED` if the element matches the provided filter, and
:cmake:variable:`OUT_MISMATCHED` otherwise. Before matching, the elements can optionally be
transformed by the selected :cmake:variable:`TRANSFORM`, but the elements in the out-variables are
always identical to those provided via :cmake:variable:`INPUT`.

Parameters
##########

One Value
~~~~~~~~~

:cmake:variable:`OUT_MATCHED`
  The variable named will be set to a list of elements from :cmake:variable:`INPUT` that matched
  :cmake:variable:`REGEX`.

:cmake:variable:`OUT_MISMATCHED`
  The variable named will be set to a list of elements from :cmake:variable:`INPUT` that did *not*
  match :cmake:variable:`REGEX`.

:cmake:variable:`REGEX`
  When present, this provided regular expression will be the filter  used to separate the input
  elements.
:cmake:variable:`IS_DIRECTORY`
  When present, the filter used to separate the input elements will match when an element is a
  directory.

:cmake:variable:`IS_SYMLINK`
  When present, the filter used to separate the input elements will match when an element is a
  symlink.

:cmake:variable:`IS_ABSOLUTE`
  When present, the filter used to separate the input elements will match when an element is an
  absolute path

:cmake:variable:`IS_TARGET`
  When present, the filter used to separate the input elements will match when an element names
  an existent target

:cmake:variable:`EVAL_TRUE`
  When present, the filter used to separate the input elements will match when an element
  interpreted as a `condition <https://cmake.org/cmake/help/latest/command/if.html#condition-syntax>`_
  evaluates to true using CMake's `if clause <https://cmake.org/cmake/help/latest/command/if.html>`_.
  This is primarily useful for testing a batch of conditions, such as which elements in a list of
  options are 1/ON/TRUE/YES... vs. 0/OFF/FALSE/NO/NOTFOUND...

:cmake:variable:`TRANSFORM`
  A transformation to apply to the input before matching. The outputs will not contain this
  transformation. Currently, only :cmake:`FILENAME` or :cmake:`ALIASED_TARGET` is supported.

Multi Value
~~~~~~~~~~~

:cmake:variable:`INPUT`
  List of elements to split based on :cmake:variable:`REGEX`. An empty list is accepted, so long as
  the *INPUT* keyword is provided.

Examples
########

.. code-block:: cmake

  jcm_separate_list(
    REGEX "${JCM_HEADER_REGEX}"
    TRANSFORM "FILENAME"
    OUT_MISMATCHED improperly_named
    INPUT
      "${CMAKE_CURRENT_SOURCE_DIR}/thing.hpp"
      "${CMAKE_CURRENT_SOURCE_DIR}/thINg.hxx")

.. code-block:: cmake

  jcm_separate_list(
    IS_DIRECTORY
    OUT_MATCHED directories
    OUT_MISMATCHED non_directories
    INPUT
      "/path/to/my/file.txt"
      "/path/to/my")
      "/path/to/")

   message(STATUS "${directories}" == "/path/to/my;/path/to/")
   message(STATUS "${non_directories}" == "/path/to/my/file.txt")

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_separate_list)
  jcm_parse_arguments(
    OPTIONS "IS_DIRECTORY" "IS_SYMLINK" "IS_ABSOLUTE" "IS_TARGET" "EVAL_TRUE"
    ONE_VALUE_KEYWORDS "REGEX" "OUT_MATCHED" "OUT_MISMATCHED" "TRANSFORM"
    MULTI_VALUE_KEYWORDS "INPUT"
    REQUIRES_ALL "INPUT"
    REQUIRES_ANY "OUT_MATCHED" "OUT_MISMATCHED"
    REQUIRES_ANY_1 "REGEX" "IS_DIRECTORY" "IS_SYMLINK" "IS_ABSOLUTE" "EVAL_TRUE"
    MUTUALLY_EXCLUSIVE "REGEX" "IS_DIRECTORY" "IS_SYMLINK" "IS_ABSOLUTE" "IS_TARGET" "EVAL_TRUE"
    ACCEPT_MISSING "INPUT"
    ARGUMENTS "${ARGN}")

  if(NOT ARGS_INPUT)
    if(DEFINED ARGS_OUT_MATCHED)
      set(${ARGS_OUT_MATCHED} "" PARENT_SCOPE)
    endif()
    if(DEFINED ARGS_OUT_MISMATCHED)
      set(${ARGS_OUT_MISMATCHED} "" PARENT_SCOPE)
    endif()

    return()
  endif()

  # additional argument validation
  set(supported_transforms "FILENAME|ALIASED_TARGET")
  if(DEFINED ARGS_TRANSFORM AND NOT ARGS_TRANSFORM MATCHES "${supported_transforms}")
    message(FATAL_ERROR "The TRANSFORM of ${ARGS_TRANSFORM} is not supported. "
      "It must be one of ${supported_transforms}.")
  endif()

  if("${ARGS_TRANSFORM}" STREQUAL "FILENAME" AND ARGS_IS_ABSOLUTE)
    message(AUTHOR_WARNING
      "Using 'FILENAME' as the TRANSFORM in combination with the 'IS_ABSOLUTE' to "
      "${CMAKE_CURENT_FUNCTION} is nonsensical, as all filenames are strictly not absolute. ")
  endif()

  # form internal transformation; default is no transform
  if(ARGS_TRANSFORM STREQUAL "FILENAME")
    set(selected_transformation [[
      cmake_path(GET element FILENAME transformed_element)
    ]])
  elseif(ARGS_TRANSFORM STREQUAL "ALIASED_TARGET")
    set(selected_transformation [[
      jcm_aliased_target(TARGET "${element}" OUT_TARGET transformed_element)
    ]])
  else()
    set(selected_transformation)
  endif()

  # form filter; default is a mismatch
  if(ARGS_IS_DIRECTORY)
    set(selected_filter [[
      if(IS_DIRECTORY "${transformed_element}")
        set(element_matched TRUE)
      else()
        set(element_matched FALSE)
      endif()
    ]])
  elseif(ARGS_IS_SYMLINK)
    set(selected_filter [[
      if(IS_SYMLINK "${transformed_element}")
        set(element_matched TRUE)
      else()
        set(element_matched FALSE)
      endif()
    ]])
  elseif(ARGS_IS_ABSOLUTE)
    set(selected_filter [[
      if(IS_ABSOLUTE "${transformed_element}")
        set(element_matched TRUE)
      else()
        set(element_matched FALSE)
      endif()
    ]])
  elseif(ARGS_IS_TARGET)
    set(selected_filter [[
      if(TARGET "${transformed_element}")
        set(element_matched TRUE)
      else()
        set(element_matched FALSE)
      endif()
    ]])
  elseif(DEFINED ARGS_REGEX)
    set(selected_filter [[
      string(REGEX MATCH "${ARGS_REGEX}" element_matched "${transformed_element}")
    ]])
  else()
    set(selected_filter [[
      if(${transformed_element})
        set(element_matched TRUE)
      else()
        set(element_matched FALSE)
      endif()
    ]])
  endif()

  # Split input into two lists
  set(matched_elements)
  set(mismatched_elements)
  foreach(element ${ARGS_INPUT})
    # transform element to be matched
    if(DEFINED selected_transformation)
      cmake_language(EVAL CODE "${selected_transformation}")
    else()
      set(transformed_element "${element}")
    endif()

    # compare element against selected filter
    set(element_matched FALSE)
    cmake_language(EVAL CODE "${selected_filter}")
    if(element_matched)
      list(APPEND matched_elements "${element}")
    else()
      list(APPEND mismatched_elements "${element}")
    endif()
  endforeach()

  # Set out variables
  if(DEFINED ARGS_OUT_MATCHED)
    set(${ARGS_OUT_MATCHED} "${matched_elements}" PARENT_SCOPE)
  endif()
  if(DEFINED ARGS_OUT_MISMATCHED)
    set(${ARGS_OUT_MISMATCHED} "${mismatched_elements}" PARENT_SCOPE)
  endif()
endfunction()


#[=======================================================================[.rst:

jcm_transform_list
^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_transform_list

  .. code-block:: cmake

    jcm_transform_list(
      <ABSOLUTE_PATH [BASE <path>] | NORMALIZE_PATH | PARENT_PATH | FILENAME | ALIASED_TARGET>
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

:cmake:variable:`ALIASED_TARGET`
  A transformation that treats each input item as a target name or target alias, and transform it to
  the target being aliased with :cmake:command:`jcm_aliased_target`. Excludes other transformation
  options.

One Value
~~~~~~~~~

:cmake:variable:`OUT_VAR`
  The variable named will be set to a list of transformed input elements.

:cmake:variable:`BASE`
  When the selected transformation is :cmake:variable:`ABSOLUTE_PATH`, this names the absolute path
  to the directory upon which relative paths will be made absolute. When omitted, the default is
  :cmake:variable:`CMAKE_CURRENT_SOURCE_DIR`

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

.. code-block:: cmake

  jcm_transform_list(
    ALIASED_TARGET 
    INPUT libimage::core  libimage::libimage-viewer libimage_libimage-readers
    OUT_VAR aliased_targets)

  message(STATUS 
    "${header_file_names} == libimage_libimage-core;libimage_libimage-viewer;libimage_libimage-readers")

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_transform_list)
  # Argument parsing, allowing value to INPUT to be empty
  jcm_parse_arguments(
    WITHOUT_MISSING_VALUES_CHECK
    OPTIONS "ABSOLUTE_PATH" "NORMALIZE_PATH" "PARENT_PATH" "FILENAME" "ALIASED_TARGET"
    ONE_VALUE_KEYWORDS "BASE;OUT_VAR"
    MULTI_VALUE_KEYWORDS "INPUT"
    REQUIRES_ALL "OUT_VAR"
    REQUIRES_ANY "ABSOLUTE_PATH" "NORMALIZE_PATH" "FILENAME"
    MUTUALLY_EXCLUSIVE "ABSOLUTE_PATH" "NORMALIZE_PATH" "PARENT_PATH" "FILENAME" "ALIASED_TARGET"
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
  if(DEFINED ARGS_BASE)
    if(NOT ARGS_ABSOLUTE_PATH)
      message(FATAL_ERROR
        "'BASE' may only be provided to ${CMAKE_CURRENT_FUNCTION} with the 'ABSOLUTE_PATH' "
        "transformation")
    elseif(NOT IS_ABSOLUTE "${ARGS_BASE}")
      message(FATAL_ERROR
        "The directory path provided to 'BASE' of ${CMAKE_CURRENT_FUNCTION} must be absolute.")
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
      if(IS_ABSOLUTE "${element}")
        set(transformed_element "${element}")
      else()
        set(transformed_element "${absolute_base_path}/${element}")
      endif()
    ]=])
  elseif(ARGS_NORMALIZE_PATH)
    set(selected_transformation [=[
      cmake_path(SET transformed_element NORMALIZE "${element}")
    ]=])
  elseif(ARGS_PARENT_PATH)
    set(selected_transformation [=[
      cmake_path(GET element PARENT_PATH transformed_element)
    ]=])
  elseif(ARGS_FILENAME)
    set(selected_transformation [=[
      cmake_path(GET element FILENAME transformed_element)
    ]=])
  elseif(ARGS_ALIASED_TARGET)
    set(selected_transformation [=[
      jcm_aliased_target(TARGET "${element}" OUT_TARGET transformed_element)
    ]=])
  endif()

  # Transform list
  set(transformed_results)
  foreach(element IN LISTS ARGS_INPUT)
    set(transformed_element)
    cmake_language(EVAL CODE "${selected_transformation}")
    list(APPEND transformed_results "${transformed_element}")
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
      <[OUT_IDX <out-var>]
       [OUT_ELEMENT <out-var>] >
      INPUT <item>...)

Searches :cmake:variable:`INPUT` for an item that either matches or mismatches
(when :cmake:variable:`MISMATCH` is provided) the regular expression :cmake:variable:`REGEX`.

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
