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
include(JcmSymlinks)

# private function to build targets that emit error messages instead of their intended purpose
function(_jcm_build_error_targets targets err_msg)
  string(CONCAT target_err_msgs "${err_msg}" "${ARGN}")
  string(REPLACE ";" "" target_err_msgs "${target_err_msgs}")

  set(exit_failure "${CMAKE_COMMAND}" -E false)
  set(print_err "${CMAKE_COMMAND}" -E echo "${err_msg}")

  foreach (target IN LISTS targets)
    add_custom_target(
      ${target}
      COMMAND "${print_err}"
      COMMAND "${exit_failure}"
    )
  endforeach ()
endfunction()

#[=======================================================================[.rst:

jcm_create_clang_format_targets
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_create_clang_format_targets

  .. code-block:: cmake

    jcm_create_clang_format_targets(
      [QUIET]
      [STYLE_FILE <path>]
      [EXCLUDE_REGEX <regex>]
      [COMMAND <command|target>]
      [ADDITIONAL_PATHS <path>...]
      SOURCE_TARGETS <target>...
    )

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
~~~~~~~~~~

:cmake:variable:`QUIET`
  Omits the --verbose option to the underlying clang-format executable.

:cmake:variable:`WITHOUT_TOP_LEVEL_CHECK`
  Causes this function not check if it's being called in the top-level project.

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
      completely/separate/file.cpp
  )

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_create_clang_format_targets)
  jcm_parse_arguments(
    OPTIONS "QUIET" "WITHOUT_TOP_LEVEL_CHECK"
    MULTI_VALUE_KEYWORDS "ADDITIONAL_PATHS;SOURCE_TARGETS"
    ONE_VALUE_KEYWORD "EXCLUDE_REGEX" "COMMAND" "STYLE_FILE"
    REQUIRES_ALL "SOURCE_TARGETS"
    ARGUMENTS "${ARGN}"
  )

  if (NOT PROJECT_IS_TOP_LEVEL AND NOT ARGS_WITHOUT_TOP_LEVEL_CHECK)
    return()
  endif ()

  # Default arguments
  if (ARGS_STYLE_FILE)
    set(format_style_file "${ARGS_STYLE_FILE}")
  else ()
    set(format_style_file "${PROJECT_SOURCE_DIR}/.clang-format")
  endif ()

  if (DEFINED ARGS_COMMAND)
    set(clang_format_cmd "${ARGS_COMMAND}")
  else ()
    set(clang_format_cmd clang::format)
    if (NOT TARGET clang::format)
      _jcm_build_error_targets("clang-format;clang-format-check"
        "The clang-format executable could not be found!\n"
        "Maybe you forgot to call 'find_package(ClangFormat)'")
      return()
    endif ()
  endif ()

  # Warn about targets already being created to prevent less expressive warning later
  set(target_existed FALSE)
  foreach (target clang-format clang-format-check)
    if (TARGET ${target})
      message(WARNING "The target '${target}' already exists. ${CMAKE_CURRENT_FUNCTION} will not "
        "create this target")
      set(target_existed TRUE)
    endif ()
  endforeach ()

  if (target_existed)
    return()
  endif ()

  # follow symlinks (mostly for Windows) - will also clean path & check for existence
  jcm_follow_symlinks(PATHS "${format_style_file}" OUT_VAR target_format_style_file)
  if (NOT target_format_style_file)
    if (NOT format_style_file STREQUAL target_format_style_file)
      set(supplementary_symlink_msg " (pointed to by symlink '${format_style_file}')")
    endif ()

    _jcm_build_error_targets("clang-format;clang-format-check"
      "The expected clang-format configuration file is not present for project ${PROJECT_NAME}"
      "${supplementary_symlink_msg}: ${target_format_style_file}")
    return()
  endif ()

  set(format_style_file "${target_format_style_file}")

  # Collect all sources from input targets

  set(files_to_format)
  foreach (target ${ARGS_SOURCE_TARGETS})
    get_target_property(source_dir ${target} SOURCE_DIR)
    get_target_property(interface_sources ${target} INTERFACE_SOURCES)
    get_target_property(sources ${target} SOURCES)

    foreach (sources_variable interface_sources sources)
      set(sources_variable "${${sources_variable}}")
      if (NOT sources_variable)
        continue()
      endif ()

      jcm_transform_list(ABSOLUTE_PATH
        BASE "${source_dir}"
        INPUT "${sources_variable}"
        OUT_VAR absolute_source_paths)
      jcm_transform_list(NORMALIZE_PATH
        INPUT "${absolute_source_paths}"
        OUT_VAR absolute_source_paths)

      list(APPEND files_to_format "${absolute_source_paths}")
    endforeach ()
  endforeach ()

  list(REMOVE_DUPLICATES files_to_format)

  # Filter out unwanted source files
  if (DEFINED ARGS_EXCLUDE_REGEX AND files_to_format)
    list(FILTER files_to_format EXCLUDE REGEX "${ARGS_EXCLUDE_REGEX}")
    if (NOT files_to_format)
      message(
        AUTHOR_WARNING
        "All of the sources for targets ${ARGS_SOURCE_TARGETS} were excluded by the EXCLUDE_REGEX: "
        "${ARGS_EXCLUDE_REGEX}")
    endif ()
  endif ()

  # Add additional files
  if (DEFINED ARGS_ADDITIONAL_PATHS)
    jcm_expand_directories(PATHS "${ARGS_ADDITIONAL_PATHS}" GLOB "*" OUT_VAR globbed_files)
    jcm_transform_list(NORMALIZE_PATH INPUT "${globbed_files}" OUT_VAR globbed_files)
    list(APPEND files_to_format "${globbed_files}")
  endif ()

  # Create targets to run clang-format

  if (NOT files_to_format)
    message(AUTHOR_WARNING
      "No source files in project ${PROJECT_NAME} will be provided to clang-format.")
  endif ()

  set(verbose_flag)
  if (NOT ARGS_QUIET)
    set(verbose_flag ";--verbose")
  endif ()

  set(base_cmd "${clang_format_cmd}" -style=file:\"${format_style_file}\" ${verbose_flag})
  add_custom_target(
    clang-format COMMAND ${base_cmd} -i ${files_to_format})
  add_custom_target(
    clang-format-check COMMAND ${base_cmd} --dry-run --Werror ${files_to_format})
  set_target_properties(clang-format clang-format-check PROPERTIES EXCLUDE_FROM_ALL TRUE)
endfunction()


#[=======================================================================[.rst:

jcm_create_doxygen_target
^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_create_doxygen_target

  .. code-block:: cmake

    jcm_create_doxygen_target(
      [README_MAIN_PAGE]
      [EXCLUDE_REGEX <regex>]
      [OUTPUT_DIRECTORY <dir>]
      <[SOURCE_TARGETS <target>...]
       [ADDITIONAL_PATHS <path>...]>
    )

Creates a target, "doxygen-docs", that generates documentation of the provided
:cmake:variable:`TARGETS`'s header files and any :cmake:variable:`ADDITIONAL_PATHS` using Doxygen.
All of the header files in all of the interface header sets of the targets are gathered for
Doxygen, with the exception of those that match :cmake:variable:`EXCLUDE_REGEX`, if provided.

Doxygen will strip include directories from these paths such that the displayed include commands
have the proper include paths and not absolute paths. This function will provide all of the include
targets' `INTERFACE_INCLUDE_DIRECTORIES`, with any generator expressions removed, as include
directories for Doxygen to strip.

The following Doxygen related variables are set by this function:

- :cmake:variable:`DOXYGEN_STRIP_FROM_INC_PATH`
- :cmake:variable:`DOXYGEN_OUTPUT_DIRECTORY`
- :cmake:variable:`DOXYGEN_USE_MDFILE_AS_MAINPAGE`

This function has no effect when :cmake:variable:`<JCM_PROJECT_PREFIX>_BUILD_DOCS` is not set.
Ensure to call :cmake:`find_package(Doxygen)` before using this function.

Parameters
##########

Options
~~~~~~~

:cmake:variable:`README_MAIN_PAGE`
  Sets DOXYGEN_USE_MDFILE_AS_MAINPAGE to the project's root README.md file, such that Doxygen will
  use the project's readme as the main page.

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
    SOURCE_TARGETS libbbq::libbbq
  )

.. code-block:: cmake

  jcm_create_doxygen_target(
    README_MAIN_PAGE
    SOURCE_TARGETS libbbq::libbbq libbbq::vegetarian
    EXCLUDE_REGEX "export_macros.hpp$"
    ADDITIONAL_PATHS ../completely/separate/file.hpp
  )

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_create_doxygen_target)
  jcm_parse_arguments(
    OPTIONS "README_MAIN_PAGE" "EXCLUDE_BUILD_DIRECTORY"
    ONE_VALUE_KEYWORDS "OUTPUT_DIRECTORY" "EXCLUDE_REGEX"
    MULTI_VALUE_KEYWORDS "SOURCE_TARGETS;ADDITIONAL_PATHS"
    REQUIRES_ANY "SOURCE_TARGETS;ADDITIONAL_PATHS"
    ARGUMENTS "${ARGN}")

  if (NOT ${JCM_PROJECT_PREFIX_NAME}_BUILD_DOCS)
    return()
  endif ()

  # Usage Guards
  if (NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL JCM_PROJECT_DOCS_DIR)
    message(AUTHOR_WARNING
      "${CMAKE_CURRENT_FUNCTION} should be invoked in ${JCM_PROJECT_DOCS_DIR}/CMakeLists.txt")
  endif ()


  if (NOT TARGET Doxygen::doxygen)
    _jcm_build_error_targets("doxygen-docs"
      "The doxygen executable could not be found!\n"
      "Maybe you forgot to call 'find_package(Doxygen)'")
    return()
  endif ()

  # Default Arguments
  if (NOT DEFINED ARGS_OUTPUT_DIRECTORY)
    set(ARGS_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/doxygen")
  endif ()

  # Extract all include directories from targets
  set(include_dirs)
  set(doxygen_input_files)
  foreach (target ${ARGS_SOURCE_TARGETS})
    get_target_property(interface_include_dirs ${target} INTERFACE_INCLUDE_DIRECTORIES)
    string(REGEX REPLACE "\\$<[A-Z_]*:|>" "" interface_include_dirs "${interface_include_dirs}")
    list(APPEND include_dirs ${interface_include_dirs})

    get_target_property(interface_header_sets ${target} INTERFACE_HEADER_SETS)
    foreach (header_set_name IN LISTS interface_header_sets)
      get_target_property(files_in_header_set ${target} HEADER_SET_${header_set_name})
      list(APPEND doxygen_input_files ${files_in_header_set})
    endforeach ()
  endforeach ()

  list(REMOVE_DUPLICATES include_dirs)
  list(REMOVE_DUPLICATES doxygen_input_files)

  # Apply exclude regex
  if (DEFINED ARGS_EXCLUDE_REGEX)
    list(FILTER doxygen_input_files EXCLUDE REGEX "${ARGS_EXCLUDE_REGEX}")
  endif ()

  # Append any additional paths to Doxygen's input
  if (ARGS_ADDITIONAL_PATHS)
    jcm_transform_list(
      ABSOLUTE_PATH
      INPUT "${ARGS_ADDITIONAL_PATHS}"
      OUT_VAR ARGS_ADDITIONAL_PATHS)

    jcm_transform_list(
      NORMALIZE_PATH
      INPUT "${ARGS_ADDITIONAL_PATHS}"
      OUT_VAR ARGS_ADDITIONAL_PATHS)

    list(APPEND doxygen_input_files "${ARGS_ADDITIONAL_PATHS}")
  endif ()

  # Check for valuable input files
  if (NOT doxygen_input_files)
    message(AUTHOR_WARNING "No header files or additional paths will be provided to Doxygen.")
  endif ()

  # Set README.md as main page
  if (ARGS_README_MAIN_PAGE)
    set(readme "${PROJECT_SOURCE_DIR}/README.md")
    if (NOT EXISTS "${readme}")
      message(WARNING "The README_MAIN_PAGE option was specified but the "
        "README file doesn't exist: ${readme}")
    endif ()

    set(DOXYGEN_USE_MDFILE_AS_MAINPAGE "${readme}")
  endif ()

  # Target to generate Doxygen documentation
  set(DOXYGEN_STRIP_FROM_INC_PATH "${include_dirs}")
  set(DOXYGEN_OUTPUT_DIRECTORY "${ARGS_OUTPUT_DIRECTORY}")
  doxygen_add_docs(doxygen-docs "${header_files}" ALL WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}")
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
      [BUILD_DIRECTORY <dir>]
    )

Creates custom target "sphinx-docs" which invokes the `Sphinx::build` target, or the provided
:cmake:variable:`COMMAND`, to generate Sphinx documentation from the default source directory, or
:cmake:variable:`SOURCE_DIRECTORY`, if provided. When :cmake:variable:`CONFIGURE_CONF_PY` is set,
Sphinx's configuration file, `conf.py`, will be generated by configuring an input template,
`conf.py.in`, from the source directory to :cmake:variable:`CMAKE_CURRENT_BINARY_DIR`. This will
then be provided as configuration directory path to the sphinx command with its `-c` option.

Call :cmake:`find_package(Sphinx)` in order to introduce the `Sphinx::build` target before using
this function.  However, `Sphinx::build` need not be available to use this function. In this
situation, the generated "sphinx-docs" target will emit errors when built, but CMake configuration
will not be hindered.

This function has no effect when :cmake:variable:`<JCM_PROJECT_PREFIX>_BUILD_DOCS` is not set.


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
    BUILD_DIRECTORY "sphinx/latex"
  )

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_create_sphinx_target)
  jcm_parse_arguments(
    OPTIONS "CONFIGURE_CONF_PY"
    ONE_VALUE_KEYWORDS "COMMAND" "SOURCE_DIRECTORY" "BUILD_DIRECTORY"
    ARGUMENTS "${ARGN}")

  if (NOT ${JCM_PROJECT_PREFIX_NAME}_BUILD_DOCS)
    return()
  endif ()

  # Usage Guards
  if (NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL JCM_PROJECT_DOCS_DIR)
    message(AUTHOR_WARNING
      "${CMAKE_CURRENT_FUNCTION} should be invoked in ${JCM_PROJECT_DOCS_DIR}/CMakeLists.txt")
  endif ()

  # Default Arguments
  if (DEFINED ARGS_COMMAND)
    set(sphinx_cmd "${ARGS_COMMAND}")
  else ()
    set(sphinx_cmd Sphinx::build)
    if (NOT TARGET Sphinx::build)
      _jcm_build_error_targets("sphinx-docs"
        "The sphinx build executable could not be found!\n"
        "Maybe you forgot to call 'find_package(Sphinx)'")
      return()
    endif ()
  endif ()

  if (NOT DEFINED ARGS_SOURCE_DIRECTORY)
    set(sphinx_source_dir "${CMAKE_CURRENT_SOURCE_DIR}")
  elseif (ABSOLUTE "${ARGS_SOURCE_DIRECTORY}")
    set(sphinx_source_dir "${ARGS_SOURCE_DIRECTORY}")
  else ()
    set(sphinx_source_dir "${CMAKE_CURRENT_SOURCE_DIR}/${ARGS_SOURCE_DIRECTORY}")
  endif ()

  if (NOT DEFINED ARGS_BUILD_DIRECTORY)
    set(sphinx_build_dir "${CMAKE_CURRENT_BINARY_DIR}/sphinx")
  elseif (ABSOLUTE "${ARGS_BUILD_DIRECTORY}")
    set(sphinx_build_dir "${ARGS_BUILD_DIRECTORY}")
  else ()
    set(sphinx_build_dir "${CMAKE_CURRENT_BINARY_DIR}/${ARGS_BUILD_DIRECTORY}")
  endif ()

  if (ARGS_CONFIGURE_CONF_PY)
    configure_file("${sphinx_source_dir}/conf.py.in" "conf.py")
    set(sphinx_config_dir "${CMAKE_CURRENT_BINARY_DIR}")
  else ()
    set(sphinx_config_dir "${sphinx_source_dir}")
  endif ()

  if (NOT ARGS_BUILDER)
    set(ARGS_BUILDER "html")
  endif ()

  # Verify locations

  if (NOT EXISTS "${sphinx_source_dir}")
    _jcm_build_error_targets("sphinx-docs"
      "Sphinx source directory does not exist: ${sphinx_source_dir}")
  endif ()

  # Build Target
  add_custom_target(sphinx-docs
    COMMAND
    ${sphinx_cmd}
    -c ${sphinx_config_dir}
    -b ${ARGS_BUILDER}
    "${sphinx_source_dir}"
    "${sphinx_build_dir}")
endfunction()
