include_guard()

include(JcmParseArguments)
include(JcmExpandDirectories)
include(JcmCanonicalStructure)
include(JcmSeparateList)

#
# Creates a target, "doxygen-docs", that generates documentation of the provided
# TARGETS using Doxygen. Doxygen will generate documentation from the header
# files (those matching JCM_HEADER_EXTENSION) within the TARGETS'
# INTERFACE_INCLUDE_DIRECTORIES. EXCLUDE_REGEX can be provided to exclude any of
# these files or paths from Doxygen's input. The EXCLUDE_REGEX will be applied
# to absolute paths.
#
# Arguments:
#
# TARGETS: multi-value arg; list of targets to generate Doxygen documentation
# for.
#
# ADDITIONAL_PATHS; multi-value arg; list of paths to provide to Doxygen as
# input in addition to the header files from TARGETS. If directories are
# provided, CMake's doxygen_add_docs() command will automatically extract all
# contained files that aren't excluded by their exclude patterns. The paths are
# not subject to the EXCLUDE_REGEX.
#
# EXCLUDE_REGEX: one-value arg; Regular expression used to filter the TARGETS'
# interface header files from being passed to Doxygen. Optional.
#
# README_MAIN_PAGE; option: both adds the current project's README.md file to
# Doxygen's list of input files and sets DOXYGEN_USE_MDFILE_AS_MAINPAGE to it,
# such that Doxygen will use the project's readme as the main page.
#
function(jcm_create_doxygen_target)
  jcm_parse_arguments(
    OPTIONS "README_MAIN_PAGE"
    MULTI_VALUE_KEYWORDS "TARGETS;ADDITIONAL_PATHS;EXCLUDE_REGEX"
    REQUIRES_ANY "TARGETS;ADDITIONAL_PATHS" ARGUMENTS "${ARGN}")

  if (NOT DOXYGEN_FOUND)
    message(FATAL_ERROR "Doxygen must be previously found to use ${CMAKE_CURRENT_FUNCTION}")
  endif ()

  # Extract all include directories from targets
  set(include_dirs)
  foreach (target ${ARGS_TARGETS})
    get_target_property(target_dirs ${target} INTERFACE_INCLUDE_DIRECTORIES)
    if(NOT target_dirs)
      continue()
    endif()

    string(REGEX REPLACE "\\$<BUILD_INTERFACE:|>" "" target_dirs "${target_dirs}")
    foreach (dir ${target_dirs})
      file(REAL_PATH "${dir}" full_dir)
      list(APPEND include_dirs "${full_dir}")
    endforeach ()
  endforeach ()

  list(REMOVE_DUPLICATES include_dirs)

  set(header_files)
  if (include_dirs)
    # Expand each include directory into files
    jcm_expand_directories(PATHS "${include_dirs}" GLOB
      "*${JCM_HEADER_EXTENSION}" OUT_VAR header_files)
    if (NOT header_files)
      message(WARNING "The following include directories for targets "
        "${ARGS_TARGETS} don't contain any header files meeting"
        "JCM_HEADER_EXTENSION: ${include_dirs}")
    endif ()

    # Exclude header files based on provided regex
    if (ARGS_EXCLUDE_REGEX AND header_files)
      jcm_separate_list(REGEX "${ARGS_EXCLUDE_REGEX}" IN_LIST "${header_files}"
        OUT_UNMATCHED header_files)
      if (NOT header_files)
        message(
          WARNING "All of the headers in the following include directories for "
          "targets ${ARGS_TARGETS} were excluded by the EXCLUDE_REGEX "
          "${ARGS_EXCLUDE_REGEX}: ${include_dirs}")
      endif ()
    endif ()
  endif ()

  # Append any additional paths to Doxygen's input
  set(doxygen_input "${header_files}")
  if (ARGS_ADDITIONAL_PATHS)
    list(APPEND doxygen_input "${ARGS_ADDITIONAL_PATHS}")
  endif ()

  # Set README.md as main page
  if (ARGS_README_MAIN_PAGE)
    set(readme "${PROJECT_SOURCE_DIR}/README.md")
    if (NOT EXISTS "${readme}")
      message(WARNING "The README_MAIN_PAGE option was specified but the "
        " README file doesn't exist: ${readme}")
    endif ()

    set(DOXYGEN_USE_MDFILE_AS_MAINPAGE "${readme}")
    list(APPEND doxygen_input "${readme}")
  endif ()

  # Target to generate Doxygen documentation
  set(DOXYGEN_STRIP_FROM_INC_PATH "${include_dirs}")
  set(DOXYGEN_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/doxygen")
  doxygen_add_docs(doxygen-docs "${doxygen_input}" ALL WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")
  set_target_properties(doxygen-docs PROPERTIES EXCLUDE_FROM_ALL TRUE)
endfunction()
