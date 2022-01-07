include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdExpandDirectories)
include(JgdCanonicalStructure)
include(JgdSeparateList)

#
# Creates a target, "doxygen-docs", that generates documentation of the provided
# TARGETS using Doxygen. Doxygen will generate documentation from the header
# files (those matching JGD_HEADER_EXTENSION) within the TARGETS'
# INTERFACE_INCLUDE_DIRECTORIES. EXCLUDE_REGEX can be provided to exclude any of
# these files or paths from Doxygen's input. The EXCLUDE_REGEX will be applied
# to absolute paths.
#
# Arguments:
#
# TARGETS: multi-value arg; list of targets to generate Doxygen documentation
# for.
#
# EXCLUDE_REGEX: one-value arg; Regular expression used to filter the TARGETS'
# interface header files from being passed to Doxygen.
#
function(jgd_create_doxygen_target)
  jgd_parse_arguments(MULTI_VALUE_KEYWORDS "TARGETS;EXCLUDE_REGEX" ARGUMENTS
                      "${ARGN}")
  jgd_validate_arguments(KEYWORDS "TARGETS")

  # Extract all include directories from targets
  set(include_dirs)
  foreach(target ${ARGS_TARGETS})
    get_target_property(target_dirs ${target} INTERFACE_INCLUDE_DIRECTORIES)
    string(REGEX REPLACE "\\$<BUILD_INTERFACE:|>" "" target_dirs
                         "${target_dirs}")
    foreach(dir ${target_dirs})
      file(REAL_PATH "${dir}" full_dir)
      list(APPEND include_dirs "${full_dir}")
    endforeach()
  endforeach()

  list(REMOVE_DUPLICATES include_dirs)

  if(include_dirs)
    # Expand each include directory into files
    jgd_expand_directories(PATHS "${include_dirs}" GLOB
                           "*${JGD_HEADER_EXTENSION}" OUT_VAR header_files)
    if(NOT header_files)
      message(WARNING "The following include directories for targets "
                      "${ARGS_TARGETS} don't contain any header files meeting"
                      "JGD_HEADER_EXTENSION: ${include_dirs}")
    endif()

    # Exclude header files based on provided regex
    if(ARGS_EXCLUDE_REGEX AND header_files)
      jgd_separate_list(REGEX "${ARGS_EXCLUDE_REGEX}" IN_LIST "${header_files}"
                        OUT_UNMATCHED to_keep)
      set(header_files "${to_keep}")
      if(NOT to_keep)
        message(
          WARNING "All of the headers in the following include directories for "
                  "targets ${ARGS_TARGETS} were excluded by the EXCLUDE_REGEX "
                  "${ARGS_EXCLUDE_REGEX}: ${include_dirs}")
      endif()
    endif()
  endif()

  # Target to generate Doxygen documentation
  set(DOXYGEN_STRIP_FROM_INC_PATH "${include_dirs}")
  set(DOXYGEN_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/doxygen")
  doxygen_add_docs(doxygen-docs "${header_files}" ALL
                   WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")
endfunction()
