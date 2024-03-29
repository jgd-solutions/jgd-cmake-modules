include_guard()

#[=======================================================================[.rst:

JcmCreateAccessoryTargets
-------------------------

:github:`JcmCreateAccessoryTargets`

Offers functions to create custom, "accessory" targets in a project. Here, "accessory" refers to
targets that run development operations, which could be formatting, static analysis, document
generation, etc. These targets are not targets offered by a projects, like a library or executable
target.

--------------------------------------------------------------------------

#]=======================================================================]

include(JcmArbitraryScript)
include(JcmParseArguments)
include(JcmSourceSubdirectories)
include(JcmExpandDirectories)
include(JcmListTransformations)
include(JcmCanonicalStructure)
include(JcmConfigureFiles)
include(JcmStandardDirs)
include(JcmSymlinks)

#[=======================================================================[.rst:

jcm_create_message_target
^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_create_message_target

  .. code-block:: cmake

    jcm_create_message_target(
      NAME <name>
      LEVEL <TRACE|DEBUG|VERBOSE|STATUS|NOTICE|AUTHOR_WARNING|WARNING|SEND_ERROR|FATAL_ERROR>
      MESSAGES <message>...)

Creates a custom target with the name specified by :cmake:variable:`NAME` that will emit all of the
messages provided to :cmake:variable:`MESSAGES` at the given log level, :cmake:variable:`LEVEL`.
This function and the generated target are used to easily report messages to users from a target at
**a specific log level**. This differs from a target running the `echo` cmake command (``cmake -E
echo``) because *echo* only emits messages to stdout, and without log levels. Alternative solutions
are to use `JcmArbitraryScript`_ directly, or generate a script file in project configuration and
create a target that parses it as the command.

Parameters
##########

Options
~~~~~~~~~

:cmake:variable:`ALL`
  Indicate that the created target should be added to the default build target.

One Value
~~~~~~~~~

:cmake:variable:`NAME`
  The name of the custom command to create by invoking this function.

:cmake:variable:`LEVEL`
  The log level of the messages emitted by the created command.

Multi Value
~~~~~~~~~~~

:cmake:variable:`MESSAGES`
  The string messages that will be emitted by the created command at the given log level.

Examples
########

.. code-block:: cmake

  # messages will only be emitted when target is built, not when project is configured
  if(MYLIB_SCHEMA_FILES_FOUND)
    add_custom_target(mylib_generate_sources
      COMMAND "command to actually generate sources")
  else()
    jcm_create_message_target(
      NAME mylib_generate_sources
      LEVEL FATAL_ERROR
      MESSAGES "Failed to generate sources with the given schema. Schema error ${err_message}")
  endif()

#]=======================================================================]
function(jcm_create_message_target)
  jcm_parse_arguments(
    OPTIONS "ALL"
    ONE_VALUE_KEYWORDS "NAME" "LEVEL"
    MULTI_VALUE_KEYWORDS "MESSAGES"
    REQUIRES_ALL "NAME" "LEVEL" "MESSAGES"
    ARGUMENTS "${ARGN}")

  set(acceptable_status
    "TRACE|DEBUG|VERBOSE|STATUS|NOTICE|AUTHOR_WARNING|WARNING|SEND_ERROR|FATAL_ERROR")

  if(NOT "${ARGS_LEVEL}" MATCHES "${acceptable_status}")
    message(FATAL_ERROR
      "Argument 'LEVEL' of ${CMAKE_CURRENT_FUNCTION} must be one of ${acceptable_status}")
  endif()

  if(ARGS_ALL)
    set(all_arg "ALL")
  else()
    unset(all_arg)
  endif()

  jcm_form_arbitrary_script_command(OUT_VAR message_command CODE "message(${ARGS_LEVEL} " "\"${ARGS_MESSAGES}\")")
  add_custom_target(${ARGS_NAME} ${all_arg} COMMAND ${message_command})
endfunction()

# Private function to build targets that emit error messages instead of their intended purpose
# Escape sequences (\n) in the message may cause havoc in the generated build files if not properly
# escaped themselves (\\n).
function(_jcm_build_error_targets targets err_msg)
  string(CONCAT target_err_msgs "${err_msg}" "${ARGN}")
  list(JOIN target_err_msgs "" target_err_msgs)

  set(exit_failure "${CMAKE_COMMAND}" -E false)
  set(print_err "${CMAKE_COMMAND}" -E echo "${target_err_msgs}")
  jcm_create_message_target(
    NAME ${PROJECT_NAME}_err
    LEVEL FATAL_ERROR
    MESSAGES "${target_err_msgs}")


  foreach(target IN LISTS targets)
    add_custom_target(
      ${target}
      COMMAND "${print_err}"
      COMMAND "${exit_failure}")
  endforeach()
endfunction()

#[=======================================================================[.rst:

jcm_create_clang_format_targets
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_create_clang_format_targets

  .. code-block:: cmake

    jcm_create_clang_format_targets(
      [QUIET]
      [WITHOUT_TOP_LEVEL_CHECK]
      [SKIP_NONEXISTENT_TARGETS]
      [STYLE_FILE <path>]
      [EXCLUDE_REGEX <regex>]
      [COMMAND <command|target>]
      [ADDITIONAL_PATHS <path>...]
      SOURCE_TARGETS <target>...)

Creates custom targets "clang-format" and "clang-format-check" that invoke the `clang::format`
target, or the provided :cmake:variable:`COMMAND`, on all the sources for the provided
:cmake:variable:`SOURCE_TARGETS` and any additional files within :cmake:variable:`ADDITIONAL_PATHS`.
All styling is provided by the file :cmake:variable:`STYLE_FILE`, which must exist, whether the
default value or an explicit value is used.

The created "clang-format" target will format the files in-place, while
"clang-format-check" will report any formatting errors to the console and exit with an error.
:cmake:variable:`EXCLUDE_REGEX` can filter out unwanted source files of targets
:cmake:variable:`SOURCE_TARGETS`, and will be applied to the files' absolute paths.

Call :cmake:`find_package(ClangFormat)` in order to introduce the `clang::format` target before
using this function.  However, `clang::format` need not be available to use this function. In this
situation, the generated "clang-format" and "clang-format-check" targets will emit errors when
built, but CMake configuration will not be hindered.

This function has no effect when it is not called in the top-level project, unless
:cmake:variable:`WITHOUT_TOP_LEVEL_CHECK` is provided.

Parameters
##########

Options
~~~~~~~

:cmake:variable:`QUIET`
  Omits the --verbose option to the underlying clang-format executable.

:cmake:variable:`WITHOUT_TOP_LEVEL_CHECK`
  Causes this function not check if it's being called in the top-level project.

:cmake:variable:`SKIP_NONEXISTENT_TARGETS`
  Causes the function to skip over any non-existent targets named in
  :cmake:variable:`SOURCE_TARGETS`. Otherwise, all source targets must exist.

One Value
~~~~~~~~~

:cmake:variable:`STYLE_FILE`
  An optional path to clang-format style file containing the rules used to format the files in the
  created targets. By default, :cmake:`${PROJECT_SOURCE_DIR}/.clang-format` will be used. The named
  path will be converted to an absolute, normalized path, and any symlinks will be resolved before
  providing it to the underlying clang-format command.

:cmake:variable:`EXCLUDE_REGEX`
  A regular expression used to filter out the sources extracted from the targets named in
  :cmake:variable:`SOURCE_TARGETS`. Paths matching this regex are *not* provided to clang-format.
  The regular expression is applied to the absolute, normalized version of the source file paths.

:cmake:variable:`COMMAND`
  An alternative target or command for clang-format that will be used to format the files.
  By default, the target `clang::format` will be used.

Multi Value
~~~~~~~~~~~

:cmake:variable:`ADDITIONAL_PATHS`
  Additional relative or absolute paths to files or directories which will be provided as input to
  clang-format. All paths will be converted to absolute paths with respect to
  :cmake:variable:`CMAKE_CURRENT_SOURCE_DIR`. Directories will be expanded into a list of the
  enclosed files.

:cmake:variable:`SOURCE_TARGETS`
  Targets whose sources, both header and source files, will be formatted by clang-format.

Examples
########

.. code-block:: cmake

  jcm_create_clang_format_targets(SOURCE_TARGETS libbbq::libbbq)


.. code-block:: cmake

  jcm_create_clang_format_targets(
    QUIET
    STYLE_FILE .clang-format-14
    COMMAND libbbq::customClangFormat
    SOURCE_TARGETS libbbq:libbbq
    EXCLUDE_REGEX "libbbq_config.hpp$"
    ADDITIONAL_PATHS
      completely/separate/file.hpp
      completely/separate/file.cpp)

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_create_clang_format_targets)
  jcm_parse_arguments(
    OPTIONS "QUIET" "WITHOUT_TOP_LEVEL_CHECK" "SKIP_NONEXISTENT_TARGETS"
    MULTI_VALUE_KEYWORDS "ADDITIONAL_PATHS;SOURCE_TARGETS"
    ONE_VALUE_KEYWORD "EXCLUDE_REGEX" "COMMAND" "STYLE_FILE"
    REQUIRES_ALL "SOURCE_TARGETS"
    ARGUMENTS "${ARGN}")

  if(NOT PROJECT_IS_TOP_LEVEL AND NOT ARGS_WITHOUT_TOP_LEVEL_CHECK)
    return()
  endif()

  # Default arguments
  if(ARGS_STYLE_FILE)
    set(format_style_file "${ARGS_STYLE_FILE}")
  else()
    set(format_style_file "${PROJECT_SOURCE_DIR}/.clang-format")
  endif()

  if(DEFINED ARGS_COMMAND)
    set(clang_format_cmd "${ARGS_COMMAND}")
  else()
    set(clang_format_cmd clang::format)
    if(NOT TARGET clang::format)
      _jcm_build_error_targets("clang-format;clang-format-check"
        "The clang-format executable could not be found! "
        "Maybe you forgot to call 'find_package(ClangFormat)'")
      return()
    endif()
  endif()

  # follow symlinks (mostly for Windows) - will also clean path & check for existence
  jcm_follow_symlinks(PATHS "${format_style_file}" OUT_VAR target_format_style_file)
  if(NOT target_format_style_file)
    if(NOT format_style_file STREQUAL target_format_style_file)
      set(supplementary_symlink_msg " (pointed to by symlink '${format_style_file}')")
    endif()

    _jcm_build_error_targets("clang-format;clang-format-check"
      "The expected clang-format configuration file is not present for project ${PROJECT_NAME}"
      "${supplementary_symlink_msg}: ${target_format_style_file}")
    return()
  endif()

  set(format_style_file "${target_format_style_file}")

  # Collect all sources from input targets

  set(files_to_format)
  foreach(target ${ARGS_SOURCE_TARGETS})
    if(ARGS_SKIP_NONEXISTENT_TARGETS AND NOT TARGET ${target})
      continue()
    endif()
    get_target_property(source_dir ${target} SOURCE_DIR)
    get_target_property(interface_sources ${target} INTERFACE_SOURCES)
    get_target_property(sources ${target} SOURCES)

    foreach(sources_variable interface_sources sources)
      set(sources_variable "${${sources_variable}}")
      if(NOT sources_variable)
        continue()
      endif()

      jcm_transform_list(
        ABSOLUTE_PATH
        BASE "${source_dir}"
        INPUT "${sources_variable}"
        OUT_VAR absolute_source_paths)

      jcm_transform_list(NORMALIZE_PATH
        INPUT "${absolute_source_paths}"
        OUT_VAR absolute_source_paths)

      list(APPEND files_to_format "${absolute_source_paths}")
    endforeach()
  endforeach()

  list(REMOVE_DUPLICATES files_to_format)

  # Filter out unwanted source files
  if(DEFINED ARGS_EXCLUDE_REGEX AND files_to_format)
    list(FILTER files_to_format EXCLUDE REGEX "${ARGS_EXCLUDE_REGEX}")
    if(NOT files_to_format)
      message(
        AUTHOR_WARNING
        "All of the sources for targets ${ARGS_SOURCE_TARGETS} were excluded by the EXCLUDE_REGEX: "
        "${ARGS_EXCLUDE_REGEX}")
    endif()
  endif()

  # Add additional files
  if(DEFINED ARGS_ADDITIONAL_PATHS)
    jcm_expand_directories(PATHS "${ARGS_ADDITIONAL_PATHS}" GLOB "*" OUT_VAR globbed_add_files)
    jcm_transform_list(NORMALIZE_PATH INPUT "${globbed_add_files}" OUT_VAR globbed_add_files)
    list(APPEND files_to_format "${globbed_add_files}")
  endif()

  # filter out any directories before calling clang-format. These are from the targets since
  # ARGS_ADDITIONAL_PATHS have all directories expanded and therefore didn't introduce any
  jcm_separate_list(
    IS_DIRECTORY
    INPUT "${files_to_format}"
    OUT_MATCHED reject_directories
    OUT_MISMATCHED files_to_format)
  if(reject_directories)
    message(AUTHOR_WARNING
      "Source paths extracted from the targets provided to ${CMAKE_CURRENT_FUNCTION} refer to "
      "directories. Processing will continue without them, but the existence of directories in "
      "a target's 'SOURCES' or 'INTERFACE_SOURCES' properties is indication of a mistake upstream."
      "  Targets considered: '${ARGS_TARGETS}'\n"
      "  Rejected directories: ${reject_directories}")
  endif()

  # Create targets to run clang-format

  if(NOT files_to_format)
    message(AUTHOR_WARNING
      "No source files in project ${PROJECT_NAME} will be provided to clang-format.")
  endif()

  set(verbose_flag)
  if(NOT ARGS_QUIET)
    set(verbose_flag ";--verbose")
  endif()

  set(base_cmd "${clang_format_cmd}" -style=file:\"${format_style_file}\" ${verbose_flag})

  # Warn about targets already being created to prevent less expressive warning later
  if(NOT TARGET clang-format)
    add_custom_target(clang-format COMMAND ${base_cmd} -i ${files_to_format})
    set_target_properties(clang-format PROPERTIES EXCLUDE_FROM_ALL TRUE)
  else()
    message(WARNING "The target 'clang-format' already exists. ${CMAKE_CURRENT_FUNCTION} will not "
      "create this target")
  endif()

  if(NOT TARGET clang-format-check)
    add_custom_target(clang-format-check COMMAND ${base_cmd} --dry-run --Werror ${files_to_format})
    set_target_properties(clang-format PROPERTIES EXCLUDE_FROM_ALL TRUE)
  else()
    message(WARNING "The target 'clang-format' already exists. ${CMAKE_CURRENT_FUNCTION} will not "
      "create this target")
  endif()
endfunction()


#[=======================================================================[.rst:

jcm_create_doxygen_target
^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_create_doxygen_target

  .. code-block:: cmake

    jcm_create_doxygen_target(
      [README_MAIN_PAGE]
      [SKIP_NONEXISTENT_TARGETS]
      [EXCLUDE_REGEX <regex>]
      [OUTPUT_DIRECTORY <dir>]
      <[SOURCE_TARGETS <target>...]
       [ADDITIONAL_PATHS <path>...] >)

Creates a target, "doxygen-docs", that generates documentation of the provided
:cmake:variable:`SOURCE_TARGETS`'s header files and any :cmake:variable:`ADDITIONAL_PATHS` using
Doxygen. All of the header files in all of the interface header sets of the targets are gathered for
Doxygen, with the exception of those that match :cmake:variable:`EXCLUDE_REGEX`, if provided.

Doxygen will strip include directories from these paths such that the displayed include commands
have the proper include paths and not absolute paths. This function will provide all of the include
targets' `INTERFACE_INCLUDE_DIRECTORIES`, with any generator expressions removed, as include
directories for Doxygen to strip.

The following Doxygen related variables are set by this function:

- :cmake:variable:`DOXYGEN_STRIP_FROM_INC_PATH`
- :cmake:variable:`DOXYGEN_OUTPUT_DIRECTORY`
- :cmake:variable:`DOXYGEN_USE_MDFILE_AS_MAINPAGE`

This function has no effect when :cmake:variable:`<JCM_PROJECT_PREFIX>_ENABLE_DOCS` is not set.
Ensure to call :cmake:`find_package(Doxygen)` before using this function.

Parameters
##########

Options
~~~~~~~

:cmake:variable:`README_MAIN_PAGE`
  Sets DOXYGEN_USE_MDFILE_AS_MAINPAGE to the project's root README.md file, such that Doxygen will
  use the project's readme as the main page.

:cmake:variable:`SKIP_NONEXISTENT_TARGETS`
  Causes the function to skip over any non-existent targets named in
  :cmake:variable:`SOURCE_TARGETS`. Otherwise, all source targets must exist.

One Value
~~~~~~~~~

:cmake:variable:`EXCLUDE_REGEX`
  A regular expression used to filter out the headers extracted from the targets named in
  :cmake:variable:`SOURCE_TARGETS`. The header file absolute paths matching this regex are *not*
  provided to Doxygen.

:cmake:variable:`OUTPUT_DIRECTORY`
  Directory where the documentation will be placed. By default, this is is
  :cmake:`${CMAKE_CURRENT_BINARY_DIR}/doxygen`.

Multi Value
~~~~~~~~~~~

:cmake:variable:`SOURCE_TARGETS`
  Targets whose interface header files will be documented by Doxygen

:cmake:variable:`ADDITIONAL_PATHS`
  Additional relative or absolute paths to files or directories which will be provided as input to
  Doxygen. All paths will be converted to absolute paths with respect to
  :cmake:variable:`CMAKE_CURRENT_SOURCE_DIRECTORY`. Directories will be passed directly to Doxygen.


Examples
########

.. code-block:: cmake

  jcm_create_doxygen_target(
    README_MAIN_PAGE
    SOURCE_TARGETS libbbq::libbbq)

.. code-block:: cmake

  jcm_create_doxygen_target(
    README_MAIN_PAGE
    SOURCE_TARGETS libbbq::libbbq libbbq::vegetarian
    EXCLUDE_REGEX "export_macros.hpp$"
    ADDITIONAL_PATHS ../completely/separate/file.hpp)

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_create_doxygen_target)
  jcm_parse_arguments(
    OPTIONS "README_MAIN_PAGE" "SKIP_NONEXISTENT_TARGETS"
    ONE_VALUE_KEYWORDS "OUTPUT_DIRECTORY" "EXCLUDE_REGEX"
    MULTI_VALUE_KEYWORDS "SOURCE_TARGETS;ADDITIONAL_PATHS"
    REQUIRES_ANY "SOURCE_TARGETS;ADDITIONAL_PATHS"
    ARGUMENTS "${ARGN}")

  if(NOT ${JCM_PROJECT_PREFIX_NAME}_ENABLE_DOCS)
    return()
  endif()

  # Usage Guards
  if(NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL JCM_PROJECT_DOCS_DIR)
    message(AUTHOR_WARNING
      "${CMAKE_CURRENT_FUNCTION} should be invoked in ${JCM_PROJECT_DOCS_DIR}/CMakeLists.txt")
  endif()


  if(NOT TARGET Doxygen::doxygen)
    _jcm_build_error_targets("doxygen-docs"
      "The doxygen executable could not be found! "
      "Maybe you forgot to call 'find_package(Doxygen)'")
    return()
  endif()

  # Default Arguments
  if(NOT DEFINED ARGS_OUTPUT_DIRECTORY)
    set(ARGS_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/doxygen")
  endif()

  # Extract all include directories from targets
  set(include_dirs)
  set(doxygen_input_files)
  foreach(target ${ARGS_SOURCE_TARGETS})
    if(ARGS_SKIP_NONEXISTENT_TARGETS AND NOT TARGET ${target})
      continue()
    endif()
    get_target_property(interface_include_dirs ${target} INTERFACE_INCLUDE_DIRECTORIES)
    string(REGEX REPLACE "\\$<[A-Z_]*:|>" "" interface_include_dirs "${interface_include_dirs}")
    list(APPEND include_dirs ${interface_include_dirs})

    get_target_property(interface_header_sets ${target} INTERFACE_HEADER_SETS)
    foreach(header_set_name IN LISTS interface_header_sets)
      get_target_property(files_in_header_set ${target} HEADER_SET_${header_set_name})
      list(APPEND doxygen_input_files ${files_in_header_set})
    endforeach()
  endforeach()

  list(REMOVE_DUPLICATES include_dirs)
  list(REMOVE_DUPLICATES doxygen_input_files)

  # Apply exclude regex
  if(DEFINED ARGS_EXCLUDE_REGEX)
    list(FILTER doxygen_input_files EXCLUDE REGEX "${ARGS_EXCLUDE_REGEX}")
  endif()

  # Append any additional paths to Doxygen's input
  if(ARGS_ADDITIONAL_PATHS)
    jcm_transform_list(
      ABSOLUTE_PATH
      INPUT "${ARGS_ADDITIONAL_PATHS}"
      OUT_VAR ARGS_ADDITIONAL_PATHS)

    jcm_transform_list(
      NORMALIZE_PATH
      INPUT "${ARGS_ADDITIONAL_PATHS}"
      OUT_VAR ARGS_ADDITIONAL_PATHS)

    list(APPEND doxygen_input_files "${ARGS_ADDITIONAL_PATHS}")
  endif()

  # Check for valuable input files
  if(NOT doxygen_input_files)
    message(AUTHOR_WARNING "No header files or additional paths will be provided to Doxygen.")
  endif()

  # Set README.md as main page
  if(ARGS_README_MAIN_PAGE)
    set(readme "${PROJECT_SOURCE_DIR}/README.md")
    if(NOT EXISTS "${readme}")
      message(WARNING "The README_MAIN_PAGE option was specified but the "
        "README file doesn't exist: ${readme}")
    endif()

    set(DOXYGEN_USE_MDFILE_AS_MAINPAGE "${readme}")
  endif()

  # Target to generate Doxygen documentation
  set(DOXYGEN_STRIP_FROM_INC_PATH "${include_dirs}")
  set(DOXYGEN_OUTPUT_DIRECTORY "${ARGS_OUTPUT_DIRECTORY}")
  doxygen_add_docs(doxygen-docs "${header_files}" WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}")
endfunction()


#[=======================================================================[.rst:

jcm_create_sphinx_target
^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_create_sphinx_target

  .. code-block:: cmake

    jcm_create_sphinx_target(
      [CONFIGURE_CONF_PY]
      [BUILDER <builder>]
      [COMMAND <command|target>]
      [SOURCE_DIRECTORY <dir>]
      [BUILD_DIRECTORY <dir>])

Creates custom target "sphinx-docs" which invokes the `Sphinx::build` target, or the provided
:cmake:variable:`COMMAND`, to generate Sphinx documentation from the default source directory, or
:cmake:variable:`SOURCE_DIRECTORY` if provided. When :cmake:variable:`CONFIGURE_CONF_PY` is set,
Sphinx's configuration file, `conf.py`, will be generated by configuring an input template,
`conf.py.in`, from the source directory to :cmake:variable:`CMAKE_CURRENT_BINARY_DIR`. This will
then be provided as configuration directory path to the sphinx command with its `-c` option.

Call :cmake:`find_package(Sphinx)` in order to introduce the `Sphinx::build` target before using
this function.  However, `Sphinx::build` need not be available to use this function. In this
situation, the generated "sphinx-docs" target will emit errors *when built*, but CMake configuration
will not be hindered.

This function has no effect when :cmake:variable:`<JCM_PROJECT_PREFIX>_ENABLE_DOCS` is not set.


Parameters
##########

Options
~~~~~~~

:cmake:variable:`CONFIGURE_CONF_PY`
  When provided, this function will configure Sphinx's configuration file, `conf.py`, as described
  above.

One Value
~~~~~~~~~

:cmake:variable:`BUILDER`
  Sphinx builders specify which type of documentation should be generated. Options include 'html',
  'text', 'latex', and more. The default is html.

:cmake:variable:`COMMAND`
  An alternative target or command  that will be used to format the files. By default, the target
  `Sphinx::build` will be used.

:cmake:variable:`SOURCE_DIRECTORY`
  The source directory, where the documentation files live, provided to the sphinx command/target.
  A relative path will be treated as relative with respect to
  :cmake:variable:`CMAKE_CURRENT_SOURCE_DIR`.  Default value is
  :cmake:variable:`CMAKE_CURRENT_SOURCE_DIR`.

:cmake:variable:`BUILD_DIRECTORY`
  The build directory, where the documentation will be generated, provided to the sphinx
  command/target. A relative path will be treated as relative with respect to
  :cmake:variable:`CMAKE_CURRENT_BINARY_DIR`. Default value is
  :cmake:`${CMAKE_CURRENT_BINARY_DIR}/sphinx`

Examples
########

.. code-block:: cmake

  jcm_create_sphinx_targets(CONFIGURE_CONF_PY)

.. code-block:: cmake

  jcm_create_sphinx_targets(
    CONFIGURE_CONF_PY
    BUILDER "latex"
    BUILD_DIRECTORY "sphinx/latex")

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_create_sphinx_target)
  jcm_parse_arguments(
    OPTIONS "CONFIGURE_CONF_PY"
    ONE_VALUE_KEYWORDS "COMMAND" "SOURCE_DIRECTORY" "BUILD_DIRECTORY"
    ARGUMENTS "${ARGN}")

  if(NOT ${JCM_PROJECT_PREFIX_NAME}_ENABLE_DOCS)
    return()
  endif()

  # Usage Guards
  if(NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL JCM_PROJECT_DOCS_DIR)
    message(AUTHOR_WARNING
      "${CMAKE_CURRENT_FUNCTION} should be invoked in ${JCM_PROJECT_DOCS_DIR}/CMakeLists.txt")
  endif()

  # Default Arguments
  if(DEFINED ARGS_COMMAND)
    set(sphinx_cmd "${ARGS_COMMAND}")
  else()
    set(sphinx_cmd Sphinx::build)
    if(NOT TARGET Sphinx::build)
      _jcm_build_error_targets("sphinx-docs"
        "The sphinx build executable could not be found! "
        "Maybe you forgot to call 'find_package(Sphinx)'")
      return()
    endif()
  endif()

  if(NOT DEFINED ARGS_SOURCE_DIRECTORY)
    set(sphinx_source_dir "${CMAKE_CURRENT_SOURCE_DIR}")
  elseif(ABSOLUTE "${ARGS_SOURCE_DIRECTORY}")
    set(sphinx_source_dir "${ARGS_SOURCE_DIRECTORY}")
  else()
    set(sphinx_source_dir "${CMAKE_CURRENT_SOURCE_DIR}/${ARGS_SOURCE_DIRECTORY}")
  endif()


  if(NOT DEFINED ARGS_BUILD_DIRECTORY)
    set(sphinx_build_dir "${CMAKE_CURRENT_BINARY_DIR}/sphinx")
  elseif(ABSOLUTE "${ARGS_BUILD_DIRECTORY}")
    set(sphinx_build_dir "${ARGS_BUILD_DIRECTORY}")
  else()
    set(sphinx_build_dir "${CMAKE_CURRENT_BINARY_DIR}/${ARGS_BUILD_DIRECTORY}")
  endif()

  if(ARGS_CONFIGURE_CONF_PY)
    # when conf.py.in changes, cmake will detect the change and force reconfiguration when the
    # sphinx-docs target is built. However, sphinx-build itself will not detect the change to
    # conf.py, even though it's confirmed to be updated by CMake *before* sphinx-build is invoked.
    jcm_configure_file(
      IN_FILE "${sphinx_source_dir}/conf.py.in"
      DEST_DIR "${CMAKE_CURRENT_BINARY_DIR}")
    set(sphinx_config_dir "${CMAKE_CURRENT_BINARY_DIR}")
  else()
    set(sphinx_config_dir "${sphinx_source_dir}")
  endif()

  if(NOT ARGS_BUILDER)
    set(ARGS_BUILDER "html")
  endif()

  # Verify locations

  if(NOT EXISTS "${sphinx_source_dir}")
    _jcm_build_error_targets("sphinx-docs"
      "Sphinx source directory does not exist: ${sphinx_source_dir}")
  endif()

  add_custom_target(sphinx-docs
    COMMAND
    ${sphinx_cmd}
    -c ${sphinx_config_dir}
    -b ${ARGS_BUILDER}
    "${sphinx_source_dir}"
    "${sphinx_build_dir}"
     SOURCES "${CMAKE_CURRENT_BINARY_DIR}/conf.py")
endfunction()
