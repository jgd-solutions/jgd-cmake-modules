include_guard()

include(JgdSourceSubdirectories)
include(JgdExpandDirectories)
include(JgdSeparateList)

# Locate the clang-format executable on system
find_program(
  CLANG_FORMAT_EXE
  NAMES "clang-format"
  DOC "Path to clang-format executable")

if (CLANG_FORMAT_EXE)
  message(STATUS "clang-format found: ${CLANG_FORMAT_EXE}")
else ()
  message(AUTHOR_WARNING "clang-format could NOT be found.")
endif ()

#
# Creates targets "clang-format" and "clang-format-check", that invoke
# clang-format on all the sources for the provided TARGETS and any additional
# files within ADDITIONAL_PATHS. The "clang-format" target will format the files
# in-place, while the "clang-format-check" will report any formatting errors to
# the console and exit with an error. EXCLUDE_REGEX can filter out unwanted
# source files from the provided targets, and will be applied to the files'
# absolute paths.
#
# Arguments:
#
# EXCLUDE_REGEX: one-value arg; Regular expression used to filter the collected
# project's source files before being provided to clang-format.
#
# ADDITIONAL_PATHS: multi-value arg; list of paths to files or directories that
# will be additionally provided to clang-format as input files. If directories are
# provided, all contained files will be extracted. These paths are not subject to
# EXCLUDE_REGEX.
#
# VERBOSE; option: provide the --verbose option to the underlying clang-format
# executable.
#
function(jgd_create_clang_format_targets)
  jgd_parse_arguments(MULTI_VALUE_KEYWORDS "ADDITIONAL_PATHS;TARGETS"
    ONE_VALUE_KEYWORD "EXCLUDE_REGEX" OPTIONS "VERBOSE" REQUIRES_ALL "TARGETS" ARGUMENTS "${ARGN}")

  # Usage Guards

  if (NOT CLANG_FORMAT_EXE)
    message(FATAL_ERROR "The clang-format executable must be available to use ${CMAKE_CURRENT_FUNCTION}")
  endif ()

  if (NOT EXISTS "${PROJECT_SOURCE_DIR}/.clang-format")
    message(FATAL_ERROR "The expected clang-format configuration file is not present  in ${PROJECT_NAME}: ${PROJECT_SOURCE_DIR}/.clang-format")
  endif ()

  # Collect all sources from input targets

  set(files_to_format)
  foreach (target ${ARGS_TARGETS})
    get_target_property(source_dir ${target} SOURCE_DIR)
    get_target_property(sources ${target} SOURCES)
    get_target_property(interface_sources ${target} INTERFACE_SOURCES)

    if (interface_sources)
      set(sources "${sources};${interface_sources}")
    endif ()

    foreach (source_file ${sources})
      if (IS_ABSOLUTE)
        set(abs_source_path "${source_file}")
      else ()
        set(abs_source_path "${source_dir}/${source_file}")
      endif ()
      list(APPEND files_to_format "${abs_source_path}")
    endforeach ()
  endforeach ()

  list(REMOVE_DUPLICATES files_to_format)

  # Filter out unwanted source files

  if (ARGS_EXCLUDE_REGEX AND files_to_format)
    jgd_separate_list(REGEX "${ARGS_EXCLUDE_REGEX}" IN_LIST "${files_to_format}" OUT_UNMATCHED to_keep)
    set(files_to_format "${to_keep}")
    if (NOT to_keep)
      message(
        WARNING "All of the sources for targets ${ARGS_TARGETS} were excluded by the EXCLUDE_REGEX ${ARGS_EXCLUDE_REGEX}")
    endif ()
  endif ()

  # Add additional files

  if (ARGS_ADDITIONAL_PATHS)
    jgd_expand_directories(PATHS "${ARGS_ADDITIONAL_PATHS}" GLOB "*" OUT_VAR globbed_files)
    list(APPEND files_to_format "${globbed_files}")
  endif ()

  # Create targets to run clang-format

  set(verbose_flag)
  if (ARGS_VERBOSE)
    set(verbose_flag ";--verbose")
  endif ()


  set(base_cmd "${CLANG_FORMAT_EXE}" -style=file ${verbose_flag})
  add_custom_target(
    clang-format COMMAND ${base_cmd} -i ${files_to_format})
  add_custom_target(
    clang-format-check COMMAND ${base_cmd} --dry-run --Werror ${files_to_format})
  set_target_properties(clang-format PROPERTIES EXCLUDE_FROM_ALL TRUE)
  set_target_properties(clang-format-check PROPERTIES EXCLUDE_FROM_ALL TRUE)
endfunction()
