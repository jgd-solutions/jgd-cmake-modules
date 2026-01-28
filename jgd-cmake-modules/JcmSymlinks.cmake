include_guard()

#[=======================================================================[.rst:

JcmSymlinks
-----------

:github:`JcmSymlinks`

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
       [OUT_ERROR_MESSAGE <out-var>] >
      [USE_CACHE | SUCCESS_CACHE])

Checks if the current build environment supports symbolic links by attempting to create a temporary
symbolic link in :cmake:variable:`CMAKE_CURRENT_BINARY_DIR`. The resultant error message contains a
helpful error message with a suggestion for resolving the issue on Windows OSs.

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
    "Alternatively, specific users can be granted the 'Create symbolic links' privilege.")

  macro(_set_out_args success_ error_message_)
    if(DEFINED ARGS_OUT_VAR)
      set(${ARGS_OUT_VAR} ${success_} PARENT_SCOPE)
    endif()
    if(DEFINED ARGS_OUT_ERROR_MESSAGE)
      set(${ARGS_OUT_ERROR_MESSAGE} "${error_message_}" PARENT_SCOPE)
    endif()
  endmacro()

  # Handle caching of result
  if(DEFINED JCM_SYMLINKS_AVAILABLE AND              # previously set cache
  ((ARGS_SUCCESS_CACHE AND JCM_SYMLINKS_AVAILABLE) OR # should use cached success
  (ARGS_USE_CACHE AND NOT ARGS_SUCCESS_CACHE)))       # should use any cached result
    if(JCM_SYMLINKS_AVAILABLE)
      set(success TRUE)
      set(error_message)
    endif()

    _set_out_args(${success} "${error_message}")
    return()
  endif()

  macro(_store_availability value)
    if(ARGS_USE_CACHE OR (ARGS_SUCCESS_CACHE AND ${value}))
      set(JCM_SYMLINKS_AVAILABLE ${value} CACHE BOOL
        "Stores whether build environment has symlink capabilities" FORCE)
      mark_as_advanced(JCM_SYMLINKS_AVAILABLE)
    endif()
  endmacro()

  # Test for symlink availability
  string(TIMESTAMP now)
  set(test_symlink "${CMAKE_CURRENT_BINARY_DIR}/.${CMAKE_CURRENT_FUNCTION}_test_symlink_${now}")

  file(CREATE_LINK "${CMAKE_CURRENT_BINARY_DIR}" "${test_symlink}"
    SYMBOLIC
    RESULT test_symlink_result)
  file(REMOVE "${test_symlink}")

  if(test_symlink_result EQUAL "0")
    set(success TRUE)
    set(error_message)
  else()
    set(success FALSE)
  endif()

  _store_availability(${success})
  _set_out_args(${success} "${error_message}")
endfunction()


#[=======================================================================[.rst:

jcm_check_symlinks_cloned
^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_check_symlinks_cloned

  .. code-block:: cmake

    jcm_check_symlinks_cloned(
      PATHS <path>...
      <[OUT_BROKEN_SYMLINKS <out-var>]
       [OUT_ERROR_MESSAGE <out-var>] >)

Checks if all of the :cmake:variable:`PATHS` refer to symbolic links. All of the paths must exist, or
the function will emit a fatal error. All relative paths will be converted to full-paths, based off
:cmake:variable:`CMAKE_CURRENT_SOURCE_DIR`, which is necessary for the internal :cmake:`IS_SYMLINK`
check.

As opposed to just using CMake's :cmake:`IS_SYMLINK` check, this function provides a helpful error
message with a suggestion to fix the issue when using git. This function should primarily be used
when a project includes symbolic links checked into SCM, and you would like to check if the symbolic
links were properly cloned, which isn't the default case with Windows+Git.

Parameters
##########

One Value
~~~~~~~~~

:cmake:variable:`OUT_BROKEN_SYMLINKS`
  When a broken symlinks exists, the variable named will be set a list of the the absolute paths of
  the broken symlinks. Otherwise, the variable named will be set to an empty string/list

:cmake:variable:`OUT_ERROR_MESSAGE`
  When a broken symlink exists, the variable named will be set to a helpful error message with a
  suggestion to fix the issue when using git. Otherwise, the variable named will be set to an empty
  string. The error message contains the path to the broken symlink, on failure.

Multi Value
~~~~~~~~~~~

:cmake:variable:`PATHS`
  A list of relative or absolute paths to files or directories that will be checked to be symbolic
  links

Examples
########

.. code-block:: cmake

  jcm_check_symlinks_cloned(
    OUT_BROKEN_SYMLINKS broken_symlinks
    OUT_ERROR_MESSAGE warning_message
    PATHS "data/image_to_read.png")

  if(broken_symlinks)
    message(WARNING "Will not build 'test-image' test:\n" ${warning_message})
    list(APPEND exclude_tests "test-image")
  endif()

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_check_symlinks_cloned)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "OUT_BROKEN_SYMLINKS" "OUT_ERROR_MESSAGE"
    MULTI_VALUE_KEYWORDS "PATHS"
    REQUIRES_ALL "PATHS"
    REQUIRES_ANY "OUT_BROKEN_SYMLINKS" "OUT_ERROR_MESSAGE"
    ARGUMENTS "${ARGN}")

  jcm_transform_list(ABSOLUTE_PATH INPUT "${ARGS_PATHS}" OUT_VAR ARGS_PATHS)

  set(broken_symlinks)
  set(error_message)

  foreach(symlink_path IN LISTS ARGS_PATHS)
    if(NOT EXISTS "${symlink_path}")
      message(FATAL_ERROR
        "The provided path to ${CMAKE_CURRENT_FUNCTION} does not exist. Cannot identify if this is "
        "a symbolic link or not")
    endif()

    if(NOT IS_SYMLINK "${symlink_path}")
      list(APPEND broken_symlinks "${symlink_path}")
      set(error_message
        "The following path in project ${PROJECT_NAME} is expected to be a symbolic link but is "
        "not. This is likely caused by improperly acquiring the project from source control, "
        "especially on Windows. With git, symbolic links can be enabled globally with "
        "`git config --global core.symlinks true`. Once enabled, Re-cloning the project will "
        "preserve symbolic links.")
      break()
    endif()
  endforeach()

  if(broken_symlinks)
    STRING(APPEND error_message "\n  Broken symlinks: ${broken_symlinks}")
  endif()

  # Result variables
  if(DEFINED ARGS_OUT_BROKEN_SYMLINKS)
    set(${ARGS_OUT_BROKEN_SYMLINKS} "${broken_symlinks}" PARENT_SCOPE)
  endif()

  if(DEFINED ARGS_OUT_ERROR_MESSAGE)
    set(${ARGS_OUT_ERROR_MESSAGE} "${error_message}" PARENT_SCOPE)
  endif()
endfunction()


#[=======================================================================[.rst:

jcm_follow_symlinks
^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_follow_symlinks

  .. code-block:: cmake

    jcm_follow_symlinks(
      PATHS <path>...
      <[OUT_VAR <out-var>]
       [OUT_NON_EXISTENT_INDICES <out-var>] >)

Converts the provided list of paths, :cmake:variable:`PATHS`, into a list of absolute, normalized
paths with all symbolic link chains traced to their final files/directories. Care is taken for
multiple platforms, where symbolic links may contain paths with different path separators; all
symbolic links are converted to CMake paths (\*nix separators). The target paths will be placed in
the variable named by :cmake:variable:`OUT_VAR`, and will be in the same order as the paths provided
via :cmake:variable:`PATHS`. When a non-symlink is provided, it will directly be placed in the
result.

The function checks for non-existent paths, including the provided path, intermediate symbolic links
, and the final target path. When one is reached, the associated result element is set to the
non-existent path, followed by `-NOTFOUND` (/home/test.js -> /home/test.js-NOTFOUND). These can
directly be placed in a CMake :cmake:`if` statement to check for existence. Furthermore, the
variable named by :cmake:variable:`OUT_NON_EXISTENT_INDICES` will contain the indices of all
non-existent paths in :cmake:variable:`PATHS`, and therefore the variable named by
:cmake:variable:`OUT_VAR`.

Parameters
##########

One Value
~~~~~~~~~

:cmake:variable:`OUT_VAR`
  The variable named will be set to all the paths in :cmake:variable:`PATHS`, after being converted
  to normalized, absolute paths, with all symbolic link chains traced to their final
  files/directories. Paths are in the in the same order as they're provided. See above for results
  for non-existent paths.

:cmake:variable:`OUT_NON_EXISTENT_INDICES`
  The variable named will be set to the indices of paths in :cmake:variable:`PATHS` which introduced
  a non-existent path.

Multi Value
~~~~~~~~~~~

:cmake:variable:`PATHS`
  A list of relative or absolute paths, where any paths to symbolic link chains will be followed.
  All paths will be internally converted to absolute, normalized paths.

Examples
########

.. code-block:: cmake

  # real_file.txt exists, fake_file.txt does not
  file(CREATE_LINK real_file.txt new_link.txt SYMBOLIC)

  jcm_follow_symlinks(
    PATHS real_file.txt new_link.txt fake_file.txt
    OUT_VAR followed_links)

  message(STATUS
    "${followed_links} == "
    "/home/here/real_file.txt;/home/here/real_file.txt;/home/here/fake_file.txt-NOTFOUND")

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_follow_symlinks)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "OUT_VAR" "OUT_NON_EXISTENT_INDICES"
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

    if(NOT IS_ABSOLUTE "${symlink_path}")
      set(symlink_path "${relative_symlink_base}/${symlink_path}")
    endif()

    cmake_path(SET symlink_path NORMALIZE "${symlink_path}")
    set(${out_var} "${symlink_path}" PARENT_SCOPE)
  endfunction()

  foreach(input_path IN LISTS input_paths)
    while (TRUE)
      if(EXISTS "${input_path}")
        if(IS_SYMLINK "${input_path}")
          _extract_symlink("${input_path}" input_path)
        else()
          break()
        endif()
      else()
        set(input_path "${input_path}-NOTFOUND")
        list(APPEND non_existent_indices ${current_index})
        break()
      endif()
    endwhile ()

    list(APPEND target_files "${input_path}")
    math(EXPR current_index "${current_index}+1")
  endforeach()

  # Result variables
  if(DEFINED ARGS_OUT_VAR)
    set(${ARGS_OUT_VAR} "${target_files}" PARENT_SCOPE)
  endif()

  if(DEFINED ARGS_OUT_NON_EXISTENT_INDICES)
    set(${ARGS_OUT_NON_EXISTENT_INDICES} "${non_existent_indices}" PARENT_SCOPE)
  endif()
endfunction()
