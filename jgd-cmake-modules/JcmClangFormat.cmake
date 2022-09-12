include_guard()

include(JcmSourceSubdirectories)
include(JcmExpandDirectories)
include(JcmListTransformations)

# Locate the clang-format executable on system
if(NOT CLANG_FORMAT_COMMAND)
  find_program(
    CLANG_FORMAT_COMMAND
    NAMES "clang-format"
    DOC "Path to clang-format executable")

  if (CLANG_FORMAT_COMMAND)
    message(STATUS "clang-format found: ${CLANG_FORMAT_COMMAND}")
  else ()
    message(AUTHOR_WARNING "clang-format could NOT be found.")
  endif ()
endif()

function(_jcm_build_error_clang_format_targets err_msg)
    set(exit_failure "${CMAKE_COMMAND}" -E false)
    set(print_err
      "${CMAKE_COMMAND}" -E echo "${err_msg}")
    add_custom_target(
      clang-format
      COMMAND "${print_err}"
      COMMAND "${exit_failure}")
    add_custom_target(
      clang-format-check
      COMMAND "${print_err}"
      COMMAND "${exit_failure}")
endfunction()

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
function(jcm_create_clang_format_targets)
  jcm_parse_arguments(MULTI_VALUE_KEYWORDS "ADDITIONAL_PATHS;TARGETS"
    ONE_VALUE_KEYWORD "EXCLUDE_REGEX" OPTIONS "VERBOSE" REQUIRES_ALL "TARGETS" ARGUMENTS "${ARGN}")

  if(NOT PROJECT_IS_TOP_LEVEL)
    return()
  endif()

  # Warn about targets already being created to prevent less expressive warning later
  set(target_existed FALSE)
  foreach(target clang-format clang-format-check)
    if(TARGET ${target})
      message(WARNING "The target '${target}' already exists. ${CMAKE_CURRENT_FUNCTION} will not"
                      "create this target")
      set(target_existed TRUE)
    endif()
  endforeach()

  if(target_existed)
    return()
  endif()

  # Create targets to instead emit clang-format usage errors
  if (NOT CLANG_FORMAT_COMMAND)
    set(clang_format_err "The clang-format executable must be available to use ${CMAKE_CURRENT_FUNCTION}")
  elseif (NOT EXISTS "${PROJECT_SOURCE_DIR}/.clang-format")
    set(clang_format_err "The expected clang-format configuration file is not present for project ${PROJECT_NAME}: ${PROJECT_SOURCE_DIR}/.clang-format")
  else()
    unset(clang_format_err)
  endif ()

  if (clang_format_err)
    _jcm_build_error_clang_format_targets("${clang_format_err}")
    return()
  endif ()


  # Collect all sources from input targets

  set(files_to_format)
  foreach (target ${ARGS_TARGETS})
    get_target_property(interface_sources ${target} INTERFACE_SOURCES)
    get_target_property(source_dir ${target} SOURCE_DIR)
    get_target_property(sources ${target} SOURCES)

    if(NOT interface_sources)
      set(interface_sources)
    endif()

    foreach (source_file ${sources} ${interface_sources})
      if (NOT source_file)
        continue()
      endif()

      if (IS_ABSOLUTE "${source_file}")
        set(abs_source_path "${source_file}")
      else ()
        set(abs_source_path "${source_dir}/${source_file}")
      endif ()
      list(APPEND files_to_format "${abs_source_path}")
    endforeach ()
  endforeach ()

  list(REMOVE_DUPLICATES files_to_format)

  # Filter out unwanted source files
  if (DEFINED ARGS_EXCLUDE_REGEX AND files_to_format)
    jcm_separate_list(REGEX "${ARGS_EXCLUDE_REGEX}" INPUT "${files_to_format}" OUT_UNMATCHED files_to_format)
    if (NOT files_to_format)
      message(
        AUTHOR_WARNING "All of the sources for targets ${ARGS_TARGETS} were excluded by the EXCLUDE_REGEX ${ARGS_EXCLUDE_REGEX}")
    endif ()
  endif ()

  # Add additional files
  if (DEFINED ARGS_ADDITIONAL_PATHS)
    jcm_expand_directories(PATHS "${ARGS_ADDITIONAL_PATHS}" GLOB "*" OUT_VAR globbed_files)
    list(APPEND files_to_format "${globbed_files}")
  endif ()

  # Create targets to run clang-format

  if (NOT files_to_format)
    message(
      AUTHOR_WARNING "No source files in project ${PROJECT_NAME} will be provided to clang-format.")
  endif ()

  set(verbose_flag)
  if (ARGS_VERBOSE)
    set(verbose_flag ";--verbose")
  endif ()

  set(base_cmd "${CLANG_FORMAT_COMMAND}" -style=file ${verbose_flag})
  add_custom_target(
    clang-format COMMAND ${base_cmd} -i ${files_to_format})
  add_custom_target(
    clang-format-check COMMAND ${base_cmd} --dry-run --Werror ${files_to_format})
  set_target_properties(clang-format PROPERTIES EXCLUDE_FROM_ALL TRUE)
  set_target_properties(clang-format-check PROPERTIES EXCLUDE_FROM_ALL TRUE)
endfunction()
