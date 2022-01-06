include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)

#
# Separates the list of files, FILES, into two groups, OUT_MATCHED, if the file
# name matches the provided REGEX and OUT_UNMATCHED, otherwise. FILES is not
# modified, and the file paths in the out-variables will be identical to those
# provided in FILES. Directories will added if they meet the REGEX.
#
# Arguments:
#
# FILES: multi-value arg; list of file names or file paths to separate based on
# the provided REGEX.
#
# REGEX: one-value arg; the regex to match each file name resolved from FILES
# against.
#
# OUT_MATCHED: out-value arg; the name of the variable that will store the list
# of matched files.
#
# OUT_UNMATCHED: out-value arg; the name of the variable that will store the
# list of unmatched files.
#
function(jgd_separate_file_names)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "REGEX;OUT_MATCHED;OUT_UNMATCHED"
                      MULTI_VALUE_KEYWORDS "FILES" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "REGEX;FILES" ONE_OF_KEYWORDS
                         "OUT_MATCHED;OUT_UNMATCHED")

  # Split input files into two lists
  set(matched_files)
  set(unmatched_files)
  foreach(file ${ARGS_FILES})
    # get file name from each path
    cmake_path(GET file FILENAME file_name)
    if(NOT file_name)
      message(
        FATAL_ERROR "The following path doesn't refer to a file name, it ends "
                    "with a path separator: ${file}")
    endif()

    # compare file name against regex
    string(REGEX MATCH "${ARGS_REGEX}" matched "${file_name}")
    if(matched)
      list(APPEND matched_files "${file}")
    else()
      list(APPEND unmatched_files "${file}")
    endif()
  endforeach()

  # Set out variables
  set(${ARGS_OUT_MATCHED}
      "${matched_files}"
      PARENT_SCOPE)
  set(${ARGS_OUT_UNMATCHED}
      "${unmatched_files}"
      PARENT_SCOPE)
endfunction()
