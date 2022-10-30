include_guard()

include(JcmParseArguments)
include(JcmListTransformations)

function(jcm_check_symlinks_available)
  jcm_parse_arguments(
    OPTIONS "USE_CACHE" "SUCCESS_CACHE"
    ONE_VALUE_KEYWORDS "OUT_VAR" "OUT_ERROR_MESSAGE"
    REQUIRES_ANY "OUT_VAR" "OUT_ERROR_MESSAGE"
    MUTUALLY_EXCLUSIVE "USE_CACHE" "SUCCESS_CACHE"
    ARGUMENTS "${ARGN}")

  set(success)
  set(error_message)
  macro(_set_results)
    if (DEFINED ARGS_OUT_VAR)
      set(${ARGS_OUT_VAR} ${success} PARENT_SCOPE)
    endif ()
    if (DEFINED ARGS_OUT_ERROR_MESSAGE)
      set(${ARGS_OUT_ERROR_MESSAGE} "${error_message}" PARENT_SCOPE)
    endif ()
  endmacro()

  # Handle caching of result
  if (DEFINED JCM_SYMLINKS_AVAILABLE)
    set(success ${JCM_SYMLINKS_AVAILABLE})

    if ((ARGS_SUCCESS_CACHE AND JCM_SYMLINKS_AVAILABLE) OR # used cached success
    (ARGS_USE_CACHE AND NOT ARGS_SUCCESS_CACHE))           # used any cached result
      _set_results()
      return()
    endif ()
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
    _store_availability(TRUE)
    set(success TRUE)
    unset(error_message)
  else ()
    _store_availability(FALSE)
    set(success FALSE)
    string(CONCAT error_message
      "Failed to create a test symbolic link, indicating that symbolic links are not currently "
      "available in the present build environment. On a Windows OS, you may need to turn on "
      "'Developer Mode' to allows users to create symbolic links without elevated permissions. "
      " Alternatively, specific users can be granted the 'Create symbolic links' privilege.")
  endif ()

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
