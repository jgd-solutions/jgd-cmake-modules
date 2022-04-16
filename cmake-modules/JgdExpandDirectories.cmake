include_guard()

include(JgdParseArguments)

#
# For each path in PATHS, if the path is a directory, the enclosed files
# matching GLOB will be expanded into the list specified by OUT_VAR. Paths in
# PATHS that refer directly to files will be directly added to the list
# specified by OUT_VAR. However, all of the resulting paths will be absolute.
#
# Arguments:
#
# PATHS: multi-value arg; list of input paths to expand
#
# OUT_VAR: one-value arg; the name of the variable that will store the list of
# file paths.
#
# GLOB: one-value arg; the GLOBBING expression for files within directory paths.
# The final globbing expression, used to get files within the directory path, is
# directory_path/GLOB
#
function(jgd_expand_directories)
  jgd_parse_arguments(
    ONE_VALUE_KEYWORDS
    "OUT_VAR;GLOB"
    MULTI_VALUE_KEYWORDS
    "PATHS"
    REQUIRES_ALL
    "PATHS;OUT_VAR;GLOB"
    ARGUMENTS
    "${ARGN}")

  # Fill list with all file paths
  set(file_paths)
  foreach(in_path ${ARGS_PATHS})
    # convert to abs path; if(IS_DIRECTORY) isn't well defined for rel. paths
    file(REAL_PATH "${in_path}" full_path)

    if(IS_DIRECTORY "${full_path}")
      # extract files within directory
      file(
        GLOB_RECURSE expand_files
        LIST_DIRECTORIES false
        "${full_path}/${ARGS_GLOB}")
      if(expand_files)
        list(APPEND file_paths ${expand_files})
      endif()
    else()
      # directly add file
      list(APPEND file_paths "${full_path}")
    endif()
  endforeach()

  # Set out var
  set(${ARGS_OUT_VAR}
      ${file_paths}
      PARENT_SCOPE)
endfunction()
