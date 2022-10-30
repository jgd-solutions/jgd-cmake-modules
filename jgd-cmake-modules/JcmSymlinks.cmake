include_guard()

#[=======================================================================[.rst:

JcmSymlinks
-----------

Provides functions for working with symbolic links, including those to inspect their availability
and to trace a symbolic link chain.

--------------------------------------------------------------------------

#]=======================================================================]

include(JcmParseArguments)
include(JcmListTransformations)

#[=======================================================================[.rst:

jcm_check_symlinks_available
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_check_symlinks_available

  .. code-block:: cmake

    jcm_check_symlinks_available(
      <[OUT_VAR <out-var>]
       [OUT_ERROR_MESSAGE]>
      [USE_CACHE | SUCCESS_CACHE]
    )

Checks if the current build environment has symbolic links available to it by attempting to create
a temporary symbolic link in :cmake:variable:`CMAKE_CURRENT_BINARY_DIR`. The resultant error message
 contains a helpful error message with a suggestion for resolving the issue on Windows OSs.

Additionally, the function can use various levels of caching to avoid trying to build the symbolic
link upon each invocation.

Parameters
##########

Options
~~~~~~~

:cmake:variable:`USE_CACHE`
  When provided, will cause the function to store the result of the test in the cache variable
  :cmake:variable:`JCM_SYMLINKS_AVAILABLE`. Subsequent invocations of this function will use the
  cached result.

:cmake:variable:`SUCCESS_CACHE`
  When provided, will cause the function to store the result of the test in the cache variable
  :cmake:variable:`JCM_SYMLINKS_AVAILABLE`, once the test succeeds. The test will be performed for
  each subsequent invocation of this function, until the symbolic link can be created, at which
  point the cached result will be used for further invocations.

One Value
~~~~~~~~~

:cmake:variable:`OUT_VAR`
  The variable named will be set to a boolean value, indicating if the symbolic link could be
  created (TRUE), or if the test failed (FALSE)

:cmake:variable:`OUT_ERROR_MESSAGE`
  When the test fails, the variable named will be set to helpful error message with a suggestion for
  resolving the issue on Windows OSs. Otherwise, it will contain an empty string.


Examples
########

.. code-block:: cmake

  jcm_check_symlinks_available(
    SUCCESS_CACHE
    OUT_ERROR_MESSAGE symlink_err_message)

  if(symlink_err_message)
    message(WARNING "${symlink_err_message}")
  else()
    message(STATUS "yay!")
  endif()

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_check_symlinks_available)
  jcm_parse_arguments(
    OPTIONS "USE_CACHE" "SUCCESS_CACHE"
    ONE_VALUE_KEYWORDS "OUT_VAR" "OUT_ERROR_MESSAGE"
    REQUIRES_ANY "OUT_VAR" "OUT_ERROR_MESSAGE"
    MUTUALLY_EXCLUSIVE "USE_CACHE" "SUCCESS_CACHE"
    ARGUMENTS "${ARGN}")

  set(success FALSE)
  string(CONCAT error_message
    "Failed to create a test symbolic link, indicating that symbolic links are not currently "
    "available in the present build environment. On a Windows OS, you may need to turn on "
    "'Developer Mode' to allows users to create symbolic links without elevated permissions. "
    " Alternatively, specific users can be granted the 'Create symbolic links' privilege.")

  macro(_set_results)
    if (DEFINED ARGS_OUT_VAR)
      set(${ARGS_OUT_VAR} ${success} PARENT_SCOPE)
    endif ()
    if (DEFINED ARGS_OUT_ERROR_MESSAGE)
      set(${ARGS_OUT_ERROR_MESSAGE} "${error_message}" PARENT_SCOPE)
    endif ()
  endmacro()

  # Handle caching of result
  if (DEFINED JCM_SYMLINKS_AVAILABLE AND              # previously set cache
  ((ARGS_SUCCESS_CACHE AND JCM_SYMLINKS_AVAILABLE) OR # should use cached success
  (ARGS_USE_CACHE AND NOT ARGS_SUCCESS_CACHE)))       # should use any cached result
    if (JCM_SYMLINKS_AVAILABLE)
      set(success TRUE)
      set(error_message)
    endif ()

    _set_results()
    return()
  endif ()

  macro(_store_availability value)
    if (ARGS_USE_CACHE OR (ARGS_SUCCESS_CACHE AND ${value}))
      set(JCM_SYMLINKS_AVAILABLE ${value} CACHE BOOL
        "Stores whether build environment has symlink capabilities" FORCE)
      mark_as_advanced(JCM_SYMLINKS_AVAILABLE)
    endif ()
  endmacro()

  # Test for symlink availability
  string(TIMESTAMP now)
  set(test_symlink "${CMAKE_CURRENT_BINARY_DIR}/.${CMAKE_CURRENT_FUNCTION}_test_symlink_${now}")

  file(CREATE_LINK "${CMAKE_CURRENT_BINARY_DIR}" "${test_symlink}"
    SYMBOLIC
    RESULT test_symlink_result)
  file(REMOVE "${test_symlink}")


  set(success)
  set(error_message)

  if (test_symlink_result EQUAL "0")
    set(success TRUE)
    unset(error_message)
  endif ()

  _store_availability(${success})
  _set_results()
endfunction()


function(jcm_check_symlinks_cloned)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "OUT_BROKEN_SYMLINK" "OUT_ERROR_MESSAGE"
    MULTI_VALUE_KEYWORDS "PATHS"
    REQUIRES_ALL "PATHS"
    REQUIRES_ANY "OUT_BROKEN_SYMLINK" "OUT_ERROR_MESSAGE"
    ARGUMENTS "${ARGN}")

  jcm_transform_list(ABSOLUTE_PATH INPUT "${ARGS_PATHS}" OUT_VAR ARGS_PATHS)

  set(broken_symlink)
  set(error_message)

  foreach (symlink_path IN LISTS ARGS_PATHS)
    if (NOT EXISTS "${symlink_path}")
      message(FATAL_ERROR
        "The provided path to ${CMAKE_CURRENT_FUNCTION} does not exist. Cannot identify if this is "
        "a symbolic link or not")
    endif ()

    if (NOT IS_SYMLINK "${symlink_path}")
      set(broken_symlink "${symlink_path}")
      string(CONCAT error_message
        "The following path in project ${PROJECT_NAME} is expected to be a symbolic link but is "
        "not. This is likely caused by improperly acquiring the project from source control, "
        "especially on Windows. With git, symbolic links can be enabled globally with "
        "`git config --global core.symlinks true`. Once enabled, Re-cloning the project will "
        "preserve symbolic links. Broken symbolic link: ${broken_symlink}")
      break()
    endif ()
  endforeach ()

  # Result variables
  if (DEFINED ARGS_OUT_BROKEN_SYMLINK)
    set(${ARGS_OUT_BROKEN_SYMLINK} "${broken_symlink}" PARENT_SCOPE)
  endif ()

  if (DEFINED ARGS_OUT_ERROR_MESSAGE)
    set(${ARGS_OUT_ERROR_MESSAGE} "${error_message}" PARENT_SCOPE)
  endif ()
endfunction()


function(jcm_follow_symlinks)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "OUT_VAR" "OUT_NON_EXISTENT_INDICES" "OUT_NUM_PATHS"
    MULTI_VALUE_KEYWORDS "PATHS"
    REQUIRES_ALL "PATHS"
    REQUIRES_ANY "OUT_VAR" "OUT_NON_EXISTENT_INDICES"
    ARGUMENTS "${ARGN}")

  jcm_transform_list(ABSOLUTE_PATH INPUT "${ARGS_PATHS}" OUT_VAR input_paths)
  jcm_transform_list(NORMALIZE_PATH INPUT "${input_paths}" OUT_VAR input_paths)

  set(target_files)
  set(non_existent_indices)
  set(current_index 0)

  function(_extract_symlink symlink_path out_var)
    cmake_path(GET symlink_path PARENT_PATH relative_symlink_base)
    file(READ_SYMLINK "${symlink_path}" symlink_path)
    cmake_path(CONVERT "${symlink_path}" TO_CMAKE_PATH_LIST symlink_path)

    if (NOT IS_ABSOLUTE "${symlink_path}")
      set(symlink_path "${relative_symlink_base}/${symlink_path}")
    endif ()

    cmake_path(SET symlink_path NORMALIZE "${symlink_path}")
    set(${out_var} "${symlink_path}" PARENT_SCOPE)
  endfunction()

  foreach (input_path IN LISTS input_paths)
    while (TRUE)
      if (EXISTS "${input_path}")
        if (IS_SYMLINK "${input_path}")
          _extract_symlink("${input_path}" input_path)
        else ()
          break()
        endif ()
      else ()
        set(input_path "${input_path}-NOTFOUND")
        list(APPEND non_existent_indices ${current_index})
        break()
      endif ()
    endwhile ()

    list(APPEND target_files "${input_path}")
    math(EXPR current_index "${current_index}+1")
  endforeach ()

  # Result variables
  if (DEFINED ARGS_OUT_VAR)
    set(${ARGS_OUT_VAR} "${target_files}" PARENT_SCOPE)
  endif ()

  if (DEFINED ARGS_OUT_NON_EXISTENT_INDICES)
    set(${ARGS_OUT_NON_EXISTENT_INDICES} "${non_existent_indices}" PARENT_SCOPE)
  endif ()

  if (DEFINED ARGS_OUT_NUM_PATHS)
    set(${ARGS_OUT_NUM_PATHS} "${current_index}" PARENT_SCOPE)
  endif ()
endfunction()
