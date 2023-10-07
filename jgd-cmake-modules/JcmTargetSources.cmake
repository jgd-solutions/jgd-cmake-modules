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

# classic absolute, normalized paths
# verifies files are placed correctly
# creates header file sets including the provided headers
# library or executable

#[=======================================================================[.rst:
Primarily an internal function to verify the provided source files for a **potential** target,
created to factor this logic out from :cmake:command:`jcm_add_library`,
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
  :cmake:variable:`TARGET_BINARY_DIR`. Enforcement is governed by the JCM "private" function
  :cmake:`_jcm_verify_source_locations`, from *JcmCanonicalStructure.cmake*.
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
    REQUIRES_ALL "TARGET_TYPE"
    ARGUMENTS "${ARGN}")

  # transform arguments to normalized absolute paths
  foreach(source_type "INTERFACE_HEADERS" "PUBLIC_HEADERS" "PRIVATE_HEADERS" "SOURCES")
    set(arg_name ARGS_${source_type})
    if(DEFINED ${arg_name})
      jcm_transform_list(ABSOLUTE_PATH INPUT "${${arg_name}}" OUT_VAR ${arg_name})
      jcm_transform_list(NORMALIZE_PATH INPUT "${${arg_name}}" OUT_VAR ${arg_name})
    endif()
  endforeach()

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
  elseif(NOT DEFINED ARGS_SOURCES)
    message(FATAL_ERROR "SOURCES must be provided for non-interface libraries")
  endif()

  # extract any headers from sources
  if(DEFINED ARGS_OUT_PRIVATE_HEADERS OR DEFINED ARGS_OUT_SOURCES
    OR "${ARGS_TYPE}" STREQUAL "EXECUTABLE")
    jcm_separate_list(
      INPUT "${ARGS_SOURCES}"
      REGEX "${JCM_HEADER_REGEX}"
      TRANSFORM "FILENAME"
      OUT_MATCHED headers_in_sources
      OUT_MISMATCHED non_headers_in_sources)
  else()
    unset(headers_in_sources)
    unset(non_headers_in_sources)
  endif()

  # verify file naming
  if(NOT ARGS_WITHOUT_FILE_NAMING_CHECK)
    if(DEFINED ARGS_SOURCES)
      if("${ARGS_TYPE}" STREQUAL "EXECUTABLE")
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
          "Provided source files in 'SOURCES' do not match the regex for ${ARGS_TYPE} sources,"
          "'${sources_regex}': ${incorrectly_named}.")
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
          "Provided header files in '${headers_source}' do not match the regex for ${ARGS_TYPE} "
          "headers, ${JCM_HEADER_REGEX}: ${incorrectly_named}.")
      endif()
    endforeach()

  endif()

  if(DEFINED ARGS_COMPONENT AND NOT ARGS_COMPONENT STREQUAL PROJECT_NAME
    AND "${ARGS_TYPE}" STREQUAL "EXECUTABLE")
    set(add_parent_arg "ADD_PARENT")
  else()
    unset(add_parent_arg)
  endif()
  _jcm_verify_source_locations(
    ${add_parent_arg}
    ROOT_DIRS "${PROJECT_BINARY_DIR}" "${ARGS_TARGET_SOURCE_DIR}" "${ARGS_TARGET_BINARY_DIR}"
    SOURCES
    "${ARGS_INTERFACE_HEADERS}"
    "${ARGS_PUBLIC_HEADERS}"
    "${ARGS_PRIVATE_HEADERS}"
    "${ARGS_SOURCES}")

  # Results

  # separate all headers in sources into PRIVATE_HEADERS to keep output categories pure
  if("${ARGS_TYPE}" STREQUAL "EXECUTABLE")
    set(ARGS_SOURCES "${non_headers_in_sources}")

    if(non_headers_in_sources)
      list(APPEND ARGS_PRIVATE_HEADERS "${non_headers_in_sources}")
    endif()
  endif()

  foreach(source_type "INTERFACE_HEADERS" "PUBLIC_HEADERS" "PRIVATE_HEADERS" "SOURCES")
    set(in_arg_name ARGS_${source_type}) # path values have been transformed
    set(out_arg_name ARGS_OUT_${source_type})
    if(DEFINED ${out_arg_name})
      set(${${out_arg_name}} "${${in_arg_name}}" PARENT_SCOPE)
    endif()
  endforeach()
endfunction()

#[=======================================================================[.rst:

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
  the given target. Enforcement is governed by the JCM "private" function
  :cmake:`_jcm_verify_source_locations`, from *JcmCanonicalStructure.cmake*.
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
