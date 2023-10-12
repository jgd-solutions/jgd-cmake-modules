include_guard()

#[=======================================================================[.rst:

JcmTargetSources
----------------

#]=======================================================================]

include(JcmParseArguments)
include(JcmListTransformations)
include(JcmFileNaming)
include(JcmTargetNaming)
include(JcmHeaderFileSet)

#[=======================================================================[.rst:

jcm_add_target_sources
^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_add_target_sources

  .. code-block:: cmake

    jcm_add_target_sources(
      [WITHOUT_FILE_NAMING_CHECK]
      <TARGET <target>>
      <[INTERFACE_HEADERS <header>...]
       [PUBLIC_HEADERS <header>...]
       [PRIVATE_HEADERS <header>...]
       [SOURCES <source>...] >)


After validating and cleaning the paths of the provided sources with
:cmake:command:`jcm_verify_sources`, adds them to the given target, :cmake:variable:`TARGET`, using
CMake's built-in :cmake:command:`target_sources` command and JCM's
:cmake:command:`jcm_header_file_sets`. Alias targets are supported, unlike
:cmake:command:`target_sources`.

This function will:

- for the detected target type, given by the target's :cmake:variable:`TYPE` property, ensure the
  appropriate source file types are provided based on the :cmake:variable:`INTERFACE_HEADERS`,
  :cmake:variable:`PUBLIC_HEADERS`, and :cmake:variable:`PRIVATE_HEADERS` arguments.
- transform all input file paths into normalized, absolute paths
- verify the file names as conforming to JCM's file naming conventions based on the regular
  expressions in *JcmFileNaming.cmake*
- verify the locations of the input files as conforming to the `Canonical Project Structure`_ for
  the given target.
- create PRIVATE, PUBLIC, and INTERFACE header sets with :cmake:command:`jcm_header_file_sets` using
  the respective *\*_HEADERS* parameters and any headers found in :cmake:variable:`SOURCES` for
  executable targets. This is what sets the *\*INCLUDE_DIRECTORIES* properties.
- Add the files specified by :cmake:variable:`PRIVATE_HEADERS` and :cmake:variable:`SOURCES` as
  *private* target sources via :cmake:command:`target_sources`

This function is designed for use with both executable and library targets. As such, should the
target's :cmake:variable:`TYPE` property be an executable, headers and source files may be
provided via the :cmake:variable:`SOURCES` argument. For library targets, headers must be provided
in the :cmake:variable:`INTERFACE_HEADERS`, :cmake:variable:`PUBLIC_HEADERS`, and
:cmake:variable:`PRIVATE_HEADERS` arguments, as header files in :cmake:variable:`SOURCES` will be
rejected by naming convention filters.

Parameters
##########

Options
~~~~~~~

:cmake:variable:`WITHOUT_FILE_NAMING_CHECK`
  When provided, will forgo the default check that provided header and source files conform to JCM's
  file naming conventions

One Value
~~~~~~~~~

:cmake:variable:`TARGET`
  Names an existing target onto which the provided source will be added.

Multi Value
~~~~~~~~~~~

:cmake:variable:`INTERFACE_HEADERS`
  A list of relative or absolute paths to header files required by consumers of the potential
  target, but not by the target itself. Interface header files, and therefore this parameter, are
  only meaningful for library targets. Required when :cmake:variable:`TARGET_TYPE` is
  *INTERFACE_LIBRARY*.

:cmake:variable:`PUBLIC_HEADERS`
  A list of relative or absolute paths to header files required by consumers of the potential
  target, and by the target itself. Prohibited when :cmake:variable:`TARGET_TYPE` is
  *INTERFACE_LIBRARY*.

:cmake:variable:`PRIVATE_HEADERS`
  A list of relative or absolute paths to header files required exclusively by the target itself;
  not by consumers of the potential target. Prohibited when :cmake:variable:`TARGET_TYPE` is
  *INTERFACE_LIBRARY*.

:cmake:variable:`SOURCES`
  A list of relative or absolute paths to sources files to build the potential target. Prohibited
  when :cmake:variable:`TARGET_TYPE` is *INTERFACE_LIBRARY*.
  For executable targets, private header files may be included in this list, and will have the
  same effect as providing them through :cmake:variable:`PRIVATE_HEADERS`. For other target types,
  any header files found in this parameter will cause an error.

Examples
########

.. code-block:: cmake

  jcm_add_target_sources(
    TARGET libgeometry::2d
    PUBLIC_HEADERS "shapes.hpp" "intersections.hpp"
    PRIVATE_HEADERS "shape_theory.hpp"
    SOURCES "shapes.cpp" "shape_theory.cpp")

.. code-block:: cmake

  jcm_add_target_sources(
    TARGET netman::netman
    SOURCES
      "main.cpp"
      "cli.hpp"
      "cli.cpp"
      "protocols.hpp"
      "protocols.cpp"
      "buffers.hpp"
      "buffers.cpp"
      "tracing.hpp")

#]=======================================================================]
function(jcm_add_target_sources)
  jcm_parse_arguments(
    OPTIONS "WITHOUT_FILE_NAMING_CHECK"
    ONE_VALUE_KEYWORDS "TARGET"
    MULTI_VALUE_KEYWORDS "INTERFACE_HEADERS;PUBLIC_HEADERS;PRIVATE_HEADERS;SOURCES"
    REQUIRES_ALL "TARGET"
    ARGUMENTS "${ARGN}")

  if(NOT TARGET ${ARGS_TARGET})
    message(FATAL_ERROR
      "The target provided to ${CMAKE_CURRENT_FUNCTION}, '${ARGS_TARGET}', does not exist.")
  endif()

  if(NOT DEFINED ARGS_SOURCES)
    message(FATAL_ERROR
      "SOURCES must be provided to ${CMAKE_CURRENT_FUNCTION} when adding sources to non-interface "
      "libraries. Refer to jcm_header_file_sets for adding exclusively headers to targets.")
  endif()

  get_target_property(target_type "${ARGS_TARGET}" TYPE)
  get_target_property(target_source_dir "${ARGS_TARGET}" SOURCE_DIR)
  get_target_property(target_binary_dir "${ARGS_TARGET}" BINARY_DIR)
  get_target_property(target_component "${ARGS_TARGET}" COMPONENT)

  # form conditional arguments for verify
  if(ARGS_WITHOUT_FILE_NAMING_CHECK)
    set(without_file_naming_arg WITHOUT_FILE_NAMING_CHECK)
  else()
    unset(without_file_naming_arg)
  endif()

  if(NOT target_component)
    set(target_component_arg TARGET_COMPONENT ${target_component})
  else()
    unset(target_component_arg)
  endif()

  jcm_verify_sources(
    ${without_file_naming_arg}
    ${target_component_arg}
    TARGET_TYPE "${target_type}"
    TARGET_SOURCE_DIR "${target_source_dir}"
    TARGET_BINARY_DIR "${target_binary_dir}"
    INTERFACE_HEADERS "${ARGS_INTERFACE_HEADERS}"
    PUBLIC_HEADERS "${ARGS_PUBLIC_HEADERS}"
    PRIVATE_HEADERS "${ARGS_PRIVATE_HEADERS}"
    SOURCES "${ARGS_SOURCES}"
    OUT_INTERFACE_HEADERS ARGS_INTERFACE_HEADERS
    OUT_PUBLIC_HEADERS ARGS_PUBLIC_HEADERS
    OUT_PRIVATE_HEADERS ARGS_PRIVATE_HEADERS
    OUT_SOURCES ARGS_SOURCES)

  # header properties
  if(ARGS_INTERFACE_HEADERS)
    jcm_header_file_sets(INTERFACE TARGET ${ARGS_TARGET} HEADERS "${ARGS_INTERFACE_HEADERS}")
  elseif(ARGS_PRIVATE_HEADERS)
    jcm_header_file_sets(PRIVATE TARGET ${ARGS_TARGET} HEADERS "${ARGS_PRIVATE_HEADERS}")
  endif()

  # header file sets - already assured header sources are appropriate for target
  foreach(header_scope IN ITEMS INTERFACE PUBLIC PRIVATE)
    set(header_source "ARGS_${header_scope}_HEADERS")
    if(NOT "${${header_source}}")
      continue()
    endif()
    jcm_header_file_sets(${header_scope}
      TARGET "${ARGS_TARGET}"
      HEADERS "${${header_source}}")
  endforeach()

  # sources
  # Note: empty values are considered relative paths by target_sources, which therefore adds
  # a directory as a target source. Avoid this.
  jcm_aliased_target(TARGET "${ARGS_TARGET}" OUT_TARGET ARGS_TARGET)

  if(ARGS_PRIVATE_HEADERS)
    target_sources(${ARGS_TARGET} PRIVATE "${ARGS_PRIVATE_HEADERS}")
  endif()
  if(ARGS_SOURCES)
    target_sources(${ARGS_TARGET} PRIVATE "${ARGS_SOURCES}")
  endif()
endfunction()

#[=======================================================================[.rst:

jcm_verify_sources
^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_verify_sources

  .. code-block:: cmake

    jcm_verify_sources(
      [WITHOUT_FILE_NAMING_CHECK]
      [TARGET_TYPE <STATIC_LIBRARY |
                    MODULE_LIBRARY |
                    SHARED_LIBRARY |
                    OBJECT_LIBRARY |
                    INTERFACE_LIBRARY |
                    EXECUTABLE> ]
      [TARGET_SOURCE_DIR <dir> ]
      [TARGET_BINARY_DIR <dir> ]
      [TARGET_COMPONENT <component>]
      <[INTERFACE_HEADERS <header>...]
       [PUBLIC_HEADERS <header>...]
       [PRIVATE_HEADERS <header>...]
       [SOURCES <source>...] >
      <[OUT_INTERFACE_HEADERS <out-var>]
       [OUT_PUBLIC_HEADERS <out-var>]
       [OUT_PRIVATE_HEADERS <out-var>]
       [OUT_SOURCES <out-var] >)

Primarily an internal function to verify the provided source files for a **potential** target.
Created to factor this repeated verification logic out from :cmake:command:`jcm_add_library`,
:cmake:command:`jcm_add_executable`, :cmake:command:`jcm_add_test_executable`, and
:cmake:command:`jcm_add_target_sources`. As such, its operation is important for these "public"
functions.

For a potential target of type :cmake:variable:`TARGET_TYPE`, source directory
:cmake:variable:`TARGET_SOURCE_DIR`, and binary directory :cmake:variable:`TARGET_BINARY_DIR`, this
function will:

- for the specified target type, ensure the appropriate source file types are provided based on the
  :cmake:variable:`INTERFACE_HEADERS`, :cmake:variable:`PUBLIC_HEADERS`, and
  :cmake:variable:`PRIVATE_HEADERS` arguments.
- transform all input file paths into normalized, absolute paths. The results of which will be
  available through the output variables specified by :cmake:variable:`OUT_INTERFACE_HEADERS`,
  :cmake:variable:`OUT_PUBLIC_HEADERS`, :cmake:variable:`OUT_PRIVATE_HEADERS`, and
  :cmake:variable:`OUT_SOURCES`.
- verify the file names as conforming to JCM's file naming conventions based on the regular
  expressions in *JcmFileNaming.cmake*
- verify the locations of the input files as within :cmake:variable:`TARGET_SOURCE_DIR` or
  :cmake:variable:`TARGET_BINARY_DIR`.
- remove any headers in :cmake:variable:`SOURCES`, appending them to
  :cmake:variable:`PRIVATE_HEADERS`, thereby keeping the *OUT_\** variable categories pure.

This function is designed for use with both executable and library targets. As such, should the
target's :cmake:variable:`TYPE` property be an executable, header files may be
provided via the :cmake:variable:`SOURCES` argument. For library targets, headers must be provided
in the :cmake:variable:`INTERFACE_HEADERS`, :cmake:variable:`PUBLIC_HEADERS`, and
:cmake:variable:`PRIVATE_HEADERS` arguments, as header files in :cmake:variable:`SOURCES` will be
rejected by naming convention filters.

Trusted values for the target's source and binary directories are taken as opposed to resolving
canonical values from a target name to support usage for targets outside of these directories.

Parameters
##########

Options
~~~~~~~

:cmake:variable:`WITHOUT_FILE_NAMING_CHECK`
  When provided, will forgo the default check that provided header and source files conform to JCM's
  file naming conventions

One Value
~~~~~~~~~

:cmake:variable:`TARGET_TYPE`
  Specifies the type of the potential target - that is, the target's
  `TYPE property <https://cmake.org/cmake/help/latest/prop_tgt/TYPE.html>`_. When omitted,
  an undefined library will be assumed. This is undefined to allow the various
  :cmake:`BUILD_SHARED_*` options to work as expected. Additionally, this function realistically
  only changes its behaviour when one of *EXECUTABLE* or *INTERFACE_LIBRARY* is specified.

:cmake:variable:`TARGET_SOURCE_DIR`
  Specifies a relative or absolute path to the the source directory in which the potential target
  would be created. This surrogates the target's `SOURCE_DIR property <https://cmake
  .org/cmake/help/latest/prop_tgt/SOURCE_DIR.html>`_. Relative paths are considered with respect to
  :cmake:variable:`CMAKE_CURRENT_SOURCE_DIR`, which is the argument's default value.

:cmake:variable:`TARGET_BINARY_DIR`
  Specifies a relative or absolute path to the binary directory for the potential target. This
  surrogates the target's `BINARY_DIR property <https://cmake
  .org/cmake/help/latest/prop_tgt/BINARY_DIR.html>`_. Relative paths are considered
  :cmake:variable:`CMAKE_CURRENT_BINARY_DIR`, which is the argument's default value.

:cmake:variable:`TARGET_COMPONENT`
  Specifies the component of the potential target - whether that's a library component or an
  executable component, but is only used in this function for executable components.
  Within JCM, a target's component is stored in the custom target property,
  :cmake:variable:`COMPONENT`.

:cmake:variable:`OUT_INTERFACE_HEADERS`
  The variable named will be set to a list of cleaned paths to interface headers for the
  potential target. This will contain the same number of entries as provided in
  :cmake:variable:`INTERFACE_HEADERS`.

:cmake:variable:`OUT_PUBLIC_HEADERS`
  The variable named will be set to a list of cleaned paths to public headers for the
  potential target. This will contain the same number of entries as provided in
  :cmake:variable:`PUBLIC_HEADERS`.

:cmake:variable:`OUT_PRIVATE_HEADERS`
  The variable named will be set to a list of cleaned paths to private headers for the potential
  target. For library targets (:cmake:variable:`TARGET_TYPE` `!=` *EXECUTABLE*), this will contain
  the same number of entries as provided in :cmake:variable:`PRIVATE_HEADERS`. For executable
  targets, this will contain a cleaned path for the entries in :cmake:variable:`SOURCES`,
  and a cleaned path for every header file found in :cmake:variable:`SOURCES`.

:cmake:variable:`SOURCES`
  The variable named will be set to a list of cleaned paths to sources for the potential target.
  For library targets (:cmake:variable:`TARGET_TYPE` `!=` *EXECUTABLE*), this will contain the same
  number of entries as provided in :cmake:variable:`SOURCES`. For executable targets,
  this will contain a cleaned path for the entries in :cmake:variable:`SOURCES`, excluding the
  cleaned paths for header files found in :cmake:variable:`SOURCES`, which are moved to
  :cmake:variable:`OUT_PRIVATE_HEADERS`.

Multi Value
~~~~~~~~~~~

:cmake:variable:`INTERFACE_HEADERS`
  A list of relative or absolute paths to header files required by consumers of the potential
  target, but not by the target itself. Interface header files, and therefore this parameter, are
  only meaningful for library targets. Required when the target property :cmake:variable:`TYPE` of
  the target :cmake:variable:`TARGET` is *INTERFACE_LIBRARY*.

:cmake:variable:`PUBLIC_HEADERS`
  A list of relative or absolute paths to header files required by consumers of the potential
  target, and by the target itself. Prohibited when the target property :cmake:variable:`TYPE` of
  the target :cmake:variable:`TARGET` is *INTERFACE_LIBRARY*.

:cmake:variable:`PRIVATE_HEADERS`
  A list of relative or absolute paths to header files required exclusively by the target itself;
  not by consumers of the potential target. Prohibited when the target property
  :cmake:variable:`TYPE` of the target :cmake:variable:`TARGET` is *INTERFACE_LIBRARY*.

:cmake:variable:`SOURCES`
  A list of relative or absolute paths to sources files to build the potential target. Prohibited
  when the target property :cmake:variable:`TYPE` of the target :cmake:variable:`TARGET` is
  *INTERFACE_LIBRARY*. For executable targets, private header files may be included in this
  list, and will have the same effect as providing them through :cmake:variable:`PRIVATE_HEADERS`.
  For other target types, any header files found in this parameter will cause an error.

Examples
########

.. code-block:: cmake

  # for some library target
  jcm_verify_sources(
    INTERFACE_HEADERS "wrappers_windows.hpp" "wrappers.hpp"
    PUBLIC_HEADERS "async_io.hpp" "ply_parser.hpp"
    PRIVATE_HEADERS "os_abstractions.hpp"
    SOURCES "ply_parser.cpp" "os_abstractions.cpp"
    OUT_INTERFACE_HEADERS interface_headers
    OUT_PUBLIC_HEADERS public_headers
    OUT_PRIVATE_HEADERS private_headers
    OUT_SOURCES sources)

.. code-block:: cmake

  # for some executable target
  jcm_verify_sources(
    TARGET_TYPE "EXECUTABLE"
    TARGET_SOURCE_DIR "../"
    TARGET_BINARY_DIR "../"
    PRIVATE_HEADERS "game_logic.hpp" "static_assets.hpp"
    SOURCES "main.cpp" "game_logic.cpp" "static_assets.cpp"
    OUT_PRIVATE_HEADERS private_headers
    OUT_SOURCES sources)

.. code-block:: cmake

  # for some executable component target
  jcm_verify_sources(
    TARGET_TYPE "EXECUTABLE"
    TARGET_COMPONENT "gui"
    TARGET_SOURCE_DIR "${PROJECT_SOURCE_DIR}/netcat/gui"
    TARGET_BINARY_DIR "${PROJECT_BINARY_DIR}/netcat/gui"
    SOURCES
      "main.cpp"
      "widgets.hpp"
      "widgets.cpp"
      "pages.hpp"
      "pages.cpp"
    OUT_PRIVATE_HEADERS private_headers
    OUT_SOURCES sources)

#]=======================================================================]
function(jcm_verify_sources)
  jcm_parse_arguments(
    WITHOUT_MISSING_VALUES_CHECK
    OPTIONS "WITHOUT_FILE_NAMING_CHECK"
    ONE_VALUE_KEYWORDS
    "TARGET_TYPE"
    "TARGET_SOURCE_DIR"
    "TARGET_BINARY_DIR"
    "TARGET_COMPONENT"
    "OUT_INTERFACE_HEADERS"
    "OUT_PUBLIC_HEADERS"
    "OUT_PRIVATE_HEADERS"
    "OUT_SOURCES"
    MULTI_VALUE_KEYWORDS "INTERFACE_HEADERS;PUBLIC_HEADERS;PRIVATE_HEADERS;SOURCES"
    REQUIRES_ANY "INTERFACE_HEADERS;PUBLIC_HEADERS;PRIVATE_HEADERS;SOURCES"
    REQUIRES_ANY_1
    "OUT_INTERFACE_HEADERS"
    "OUT_PUBLIC_HEADERS"
    "OUT_PRIVATE_HEADERS"
    "OUT_SOURCES"
    ARGUMENTS "${ARGN}")

  # Argument validation & defaults
  set(target_type_property_values
    "STATIC_LIBRARY|MODULE_LIBRARY|SHARED_LIBRARY|OBJECT_LIBRARY|INTERFACE_LIBRARY|EXECUTABLE")
  if(DEFINED ARGS_TARGET_TYPE AND NOT ARGS_TARGET_TYPE MATCHES "${target_type_property_values}")
    message(FATAL_ERROR
      "Invalid 'TARGET_TYPE': ${ARGS_TARGET_TYPE}. When provided, 'TARGET_TYPE' must name an "
      "acceptable value for a target's 'TYPE' property, one of: ${target_type_property_values}")
  endif()

  if(NOT DEFINED ARGS_TARGET_SOURCE_DIR)
    set(ARGS_TARGET_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
  endif()

  if(NOT DEFINED ARGS_TARGET_BINARY_DIR)
    set(ARGS_TARGET_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}")
  endif()

  # transform arguments to normalized absolute paths
  foreach(source_type IN ITEMS
    "INTERFACE_HEADERS" "PUBLIC_HEADERS" "PRIVATE_HEADERS" "SOURCES" "TARGET_SOURCE_DIR")
    set(arg_name ARGS_${source_type})
    if(DEFINED ${arg_name})
      jcm_transform_list(ABSOLUTE_PATH INPUT "${${arg_name}}" OUT_VAR ${arg_name})
      jcm_transform_list(NORMALIZE_PATH INPUT "${${arg_name}}" OUT_VAR ${arg_name})
    endif()
  endforeach()

  jcm_transform_list(
    ABSOLUTE_PATH
    BASE "${CMAKE_CURRENT_BINARY_DIR}"
    INPUT "${ARGS_TARGET_BINARY_DIR}"
    OUT_VAR ARGS_TARGET_BINARY_DIR)
  jcm_transform_list(
    NORMALIZE_PATH
    INPUT "${ARGS_TARGET_BINARY_DIR}"
    OUT_VAR ARGS_TARGET_BINARY_DIR)

  # ensure input files are appropriately provided for target type
  if("${ARGS_TARGET_TYPE}" STREQUAL "EXECUTABLE" AND DEFINED ARGS_INTERFACE_HEADERS)
    message(AUTHOR_WARNING
      "No interface headers should be added as sources to an executable target. The interface"
      "headers to target 'k{ARGS_TARGET}' will be ignored.")
    unset(ARGS_INTERFACE_HEADERS)
  endif()

  if("${ARGS_TARGET_TYPE}" STREQUAL "INTERFACE_LIBRARY")
    if(DEFINED ARGS_SOURCES OR DEFINED ARGS_PUBLIC_HEADERS OR DEFINED ARGS_PRIVATE_HEADERS)
      message(FATAL_ERROR "Interface libraries can only be added with INTERFACE_HEADERS")
    endif()
  endif()

  # extract any headers from sources
  if(DEFINED ARGS_OUT_SOURCES AND "${ARGS_TARGET_TYPE}" STREQUAL "EXECUTABLE")
    jcm_separate_list(
      INPUT "${ARGS_SOURCES}"
      REGEX "${JCM_HEADER_REGEX}"
      TRANSFORM "FILENAME"
      OUT_MATCHED headers_in_sources
      OUT_MISMATCHED non_headers_in_sources)

    if(headers_in_sources AND DEFINED ARGS_PRIVATE_HEADERS)
      message(AUTHOR_WARNING
        "Private headers are provided in both 'SOURCES' and 'PRIVATE_HEADERS' parameters. "
        "Although processing will continue without issues, it's recommended to either split all "
        "private headers into 'PRIVATE_HEADERS', or join them all in 'SOURCES', as a mixed "
        "approach may be confusing.")
    endif()
  else()
    unset(headers_in_sources)
    unset(non_headers_in_sources)
  endif()

  # verify file naming
  if(NOT ARGS_WITHOUT_FILE_NAMING_CHECK)
    if(DEFINED ARGS_SOURCES)
      if("${ARGS_TARGET_TYPE}" STREQUAL "EXECUTABLE")
        set(sources_regex "${JCM_SOURCE_REGEX}|${JCM_HEADER_REGEX}")
      else()
        set(sources_regex "${JCM_SOURCE_REGEX}")
      endif()

      jcm_separate_list(
        INPUT "${ARGS_SOURCES}"
        REGEX "${sources_regex}"
        TRANSFORM "FILENAME"
        OUT_MISMATCHED incorrectly_named)
      if(incorrectly_named)
        message(
          FATAL_ERROR
          "Provided source files in 'SOURCES' do not match the regex for ${ARGS_TARGET_TYPE} "
          "sources, '${sources_regex}': ${incorrectly_named}.")
      endif()
    endif()

    foreach(headers_source IN ITEMS ARGS_INTERFACE_HEADERS ARGS_PUBLIC_HEADERS ARGS_PRIVATE_HEADERS)
      # iterating variables instead of expanding all with 'IN LISTS' to print variable in message
      if(NOT "${${headers_source}}")
        continue()
      endif()

      jcm_separate_list(
        INPUT "${${headers_source}}"
        REGEX "${JCM_HEADER_REGEX}"
        TRANSFORM "FILENAME"
        OUT_MISMATCHED incorrectly_named)
      if(incorrectly_named)
        message(
          FATAL_ERROR
          "Provided header files in '${headers_source}' do not match the regex for "
          "${ARGS_TARGET_TYPE} headers, ${JCM_HEADER_REGEX}: ${incorrectly_named}.")
      endif()
    endforeach()

  endif()

  # verify file locations
  set(acceptable_file_root_dirs)
  list(
    APPEND acceptable_file_root_dirs
    "${PROJECT_BINARY_DIR}" "${ARGS_TARGET_SOURCE_DIR}" "${ARGS_TARGET_BINARY_DIR}")

  if(DEFINED ARGS_COMPONENT AND NOT ARGS_COMPONENT STREQUAL PROJECT_NAME
    AND "${ARGS_TARGET_TYPE}" STREQUAL "EXECUTABLE")
    cmake_path(GET ARGS_TARGET_SOURCE_DIR PARENT_PATH exec_component_parent_dir)
    list(APPEND acceptable_file_root_dirs "${exec_component_parent_dir}")
  endif()

  list(TRANSFORM acceptable_file_root_dirs PREPEND "^" OUTPUT_VARIABLE acceptable_file_roots_regex)
  list(JOIN acceptable_file_roots_regex "|" acceptable_file_roots_regex)
  jcm_separate_list(
    REGEX "${acceptable_file_roots_regex}"
    OUT_MISMATCHED misplaced_files
    INPUT
    "${ARGS_INTERFACE_HEADERS}"
    "${ARGS_PUBLIC_HEADERS}"
    "${ARGS_PRIVATE_HEADERS}"
    "${ARGS_SOURCES}")
  if(misplaced_files)
    message(FATAL_ERROR
      "The following files aren't placed within an acceptable location.\n"
      "Acceptable Locations: ${acceptable_file_root_dirs}\n"
      "Misplaced Files: ${misplaced_files}")
  endif()

  # Results

  # separate all headers in sources into PRIVATE_HEADERS to keep output categories pure
  if("${ARGS_TARGET_TYPE}" STREQUAL "EXECUTABLE")
    set(ARGS_SOURCES "${non_headers_in_sources}")

    if(headers_in_sources)
      list(APPEND ARGS_PRIVATE_HEADERS "${headers_in_sources}")
    endif()
  endif()

  foreach(source_type "INTERFACE_HEADERS" "PUBLIC_HEADERS" "PRIVATE_HEADERS" "SOURCES")
    set(in_arg_name ARGS_${source_type}) # path values have been transformed
    set(out_arg_name ARGS_OUT_${source_type})
    if(DEFINED ${out_arg_name})
      set(${${out_arg_name}} "${${in_arg_name}}" PARENT_SCOPE)
    elseif(${in_arg_name})
      message(AUTHOR_WARNING
        "No argument was provided for parameter '${out_arg_name}' of ${CMAKE_CURRENT_FUNCTION} but "
        "cleaned paths were produced. The produced paths will be discarded.")
    endif()
  endforeach()
endfunction()
