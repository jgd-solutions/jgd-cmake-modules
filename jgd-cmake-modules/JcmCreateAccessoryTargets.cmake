include_guard()

#[=======================================================================[.rst:

JcmCreateAccessoryTargets
-------------------------

Offers functions to create custom, "accessory" targets in a project. Here, "accessory" refers to
targets that run development operations, which could be formatting, static analysis, document
generation, etc. These targets are not targets offered by a projects, like a library or executable
target.

--------------------------------------------------------------------------

#]=======================================================================]

include(JcmParseArguments)
include(JcmSourceSubdirectories)
include(JcmExpandDirectories)
include(JcmListTransformations)
include(JcmCanonicalStructure)
include(JcmStandardDirs)

function(_jcm_build_error_targets err_msg targets)
    set(exit_failure "${CMAKE_COMMAND}" -E false)
    set(print_err "${CMAKE_COMMAND}" -E echo "${err_msg}")

    foreach(target IN LISTS targets)
      add_custom_target(
        ${target}
        COMMAND "${print_err}"
        COMMAND "${exit_failure}"
      )
    endforeach()
endfunction()

#[=======================================================================[.rst:

jcm_create_clang_format_targets
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_create_clang_format_targets

  .. code-block:: cmake

    jcm_create_clang_format_targets(
      [QUIET]
      [EXCLUDE_REGEX <regex>]
      [COMMAND <command>]
      [ADDITIONAL_PATHS <path>...]
      SOURCE_TARGETS <target>...
    )

Creates custom targets "clang-format" and "clang-format-check" for use with a `.clang-format` file
in the project's root. Both invoke the `clang::format` target, or the provided
:cmake:variable:`COMMAND`, on all the sources for the provided :cmake:variable:`SOURCE_TARGETS` and
any additional files within :cmake:variable:`ADDITIONAL_PATHS`, using a `.clang-format` file in the
project's root. The created "clang-format" target will format the files in-place, while
"clang-format-check" will report any formatting errors to the console and exit with an error.
:cmake:variable:`EXCLUDE_REGEX` can filter out unwanted source files of targets
:cmake:variable:`SOURCE_TARGETS`, and will be applied to the files' absolute paths.

`clang::format` need not be available to use this function.  The generated "clang-format" and
"clang-format-check" targets will emit errors when they are invoked, in this situation.

Parameters
##########

Options
~~~~~~~~~~

:cmake:variable:`QUIET`
  Omits the --verbose option to the underlying clang-format executable.

:cmake:variable:`EXCLUDE_REGEX`
  A regular expression used to filter out the sources extracted from the targets named in
  :cmake:variable:`SOURCE_TARGETS`. Paths matching this regex are *not* provided to clang-format.

:cmake:variable:`COMMAND`
  An alternative target or command for clang-format that will be used to format the files.
  By default, the target `clang::format` will be used.

:cmake:variable:`ADDITIONAL_PATHS`
  Additional relative or absolute paths to files or directories which will be provided as input to
  clang-format. All paths will be converted to absolute paths. Directories will be expanded into a
  list of the enclosed files.

:cmake:variable:`SOURCE_TARGETS`
  Targets whose sources, both header and source files, will be formatted by clang-format.

Examples
########

.. code-block:: cmake

  jcm_create_clang_format_targets(SOURCE_TARGETS libbbq::libbbq)


.. code-block:: cmake

  jcm_create_clang_format_targets(
    QUIET
    COMMAND libbbq::customClangFormat
    SOURCE_TARGETS libbbq:libbbq
    EXCLUDE_REGEX "libbbq_config.hpp$"
    ADDITIONAL_PATHS
      completely/separate/file.hpp
      completely/separate/file.cpp
  )

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_create_clang_format_targets)
  jcm_parse_arguments(
    OPTIONS "QUIET"
    MULTI_VALUE_KEYWORDS "ADDITIONAL_PATHS;SOURCE_TARGETS"
    ONE_VALUE_KEYWORD "EXCLUDE_REGEX" "COMMAND"
    REQUIRES_ALL "SOURCE_TARGETS"
    ARGUMENTS "${ARGN}"
  )

  unset(clang_format_err)

  if(DEFINED ARGS_COMMAND)
    set(clang_format_cmd "${ARGS_COMMAND}")
  else()
    set(clang_format_cmd clang::format)
    if(NOT TARGET clang::format)
      string(CONCAT clang_format_err
        "The clang-format executable could not be found!\n"
        "Maybe you forgot to call 'find_package(ClangFormat)'")
    endif()
  endif()

  # Warn about targets already being created to prevent less expressive warning later
  set(target_existed FALSE)
  foreach(target clang-format clang-format-check)
    if(TARGET ${target})
      message(WARNING "The target '${target}' already exists. ${CMAKE_CURRENT_FUNCTION} will not "
                      "create this target")
      set(target_existed TRUE)
    endif()
  endforeach()

  if(target_existed)
    return()
  endif()

  # Create targets to instead emit clang-format usage errors
  if (NOT clang_format_err AND NOT EXISTS "${PROJECT_SOURCE_DIR}/.clang-format")
    set(clang_format_err
      "The expected clang-format configuration file is not present for project ${PROJECT_NAME}: "
      "${PROJECT_SOURCE_DIR}/.clang-format"
    )
  endif ()

  if (clang_format_err)
    _jcm_build_error_targets("${clang_format_err}" "clang-format;clang-format-check")
    return()
  endif ()


  # Collect all sources from input targets

  set(files_to_format)
  foreach (target ${ARGS_SOURCE_TARGETS})
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
    jcm_separate_list(
      REGEX "${ARGS_EXCLUDE_REGEX}"
      INPUT "${files_to_format}"
      OUT_MISMATCHED files_to_format
    )
    if (NOT files_to_format)
      message(
        AUTHOR_WARNING
        "All of the sources for targets ${ARGS_SOURCE_TARGETS} were excluded by the EXCLUDE_REGEX "
        "${ARGS_EXCLUDE_REGEX}"
      )
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
      AUTHOR_WARNING "No source files in project ${PROJECT_NAME} will be provided to clang-format."
    )
  endif ()

  set(verbose_flag)
  if (NOT ARGS_QUIET)
    set(verbose_flag ";--verbose")
  endif ()

  set(base_cmd "${clang_format_cmd}" -style=file ${verbose_flag})
  add_custom_target(
    clang-format COMMAND ${base_cmd} -i ${files_to_format}
  )
  add_custom_target(
    clang-format-check COMMAND ${base_cmd} --dry-run --Werror ${files_to_format}
  )
  set_target_properties(clang-format PROPERTIES EXCLUDE_FROM_ALL TRUE)
  set_target_properties(clang-format-check PROPERTIES EXCLUDE_FROM_ALL TRUE)
endfunction()


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
    REQUIRES_ANY "TARGETS;ADDITIONAL_PATHS"
    ARGUMENTS "${ARGN}")

  if (NOT ${JCM_PROJECT_PREFIX_NAME}_BUILD_DOCS)
    return()
  endif ()

  # Usage Guards
  if(NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL JCM_PROJECT_DOCS_DIR)
    message(AUTHOR_WARNING
      "${CMAKE_CURRENT_SOURCE_DIR} should be invoked in ${JCM_PROJECT_DOCS_DIR}/CMakeLists.txt")
  endif()

  if(NOT TARGET Doxygen::doxygen)
    _jcm_build_error_targets(
      "The doxygen executable could not be found!\nMaybe you forgot to call 'find_package(Doxygen)'"
      doxygen-docs)
    return()
  endif()

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
      jcm_separate_list(REGEX "${ARGS_EXCLUDE_REGEX}" INPUT "${header_files}"
        OUT_MISMATCHED header_files)
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


function(jcm_create_sphinx_target)
  jcm_parse_arguments(
    OPTIONS "CONFIGURE_CONF_PY"
    ONE_VALUE_KEYWORDS "COMMAND" "SOURCE_DIRECTORY" "BUILD_DIRECTORY"
    ARGUMENTS "${ARGN}")

  if (NOT ${JCM_PROJECT_PREFIX_NAME}_BUILD_DOCS)
    return()
  endif ()

  # Usage Guards
  if(NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL JCM_PROJECT_DOCS_DIR)
    message(AUTHOR_WARNING
      "${CMAKE_CURRENT_SOURCE_DIR} should be invoked in ${JCM_PROJECT_DOCS_DIR}/CMakeLists.txt")
  endif()

  # Default Arguments
  if(DEFINED ARGS_COMMAND)
    set(sphinx_cmd "${ARGS_COMMAND}")
  else()
    set(sphinx_cmd Sphinx::build)
    if(NOT TARGET Sphinx::build)
      _jcm_build_error_targets(
        "The sphinx build executable could not be found!\nMaybe you forgot to call 'find_package(Sphinx)'"
        sphinx-docs)
      return()
    endif()
  endif()

  if(DEFINED ARGS_SOURCE_DIRECTORY)
    set(sphinx_source_dir "${ARGS_SOURCE_DIRECTORY}")
  else()
    set(sphinx_source_dir "${CMAKE_CURRENT_SOURCE_DIR}")
  endif()

  if(DEFINED ARGS_BUILD_DIRECTORY)
    set(sphinx_build_dir "${ARGS_BUILD_DIRECTORY}")
  else()
    set(sphinx_build_dir "${CMAKE_CURRENT_BINARY_DIR}/sphinx")
  endif()

  if(ARGS_CONFIGURE_CONF_PY)
    configure_file("${sphinx_source_dir}/conf.py.in" "conf.py")
    set(sphinx_config_dir "${CMAKE_CURRENT_BINARY_DIR}")
  else()
    set(sphinx_config_dir "${sphinx_source_dir}")
  endif()

  # Verify locations

  if(NOT EXISTS "${sphinx_source_dir}")
    _jcm_build_error_targets(
      "Sphinx source directory does not exist: ${sphinx_source_dir}" sphinx-docs)
  endif()

  # Build Target
  add_custom_target(sphinx-docs
    COMMAND
      ${sphinx_cmd}
      -c ${sphinx_config_dir}
      "${sphinx_source_dir}"
      "${sphinx_build_dir}")
endfunction()
