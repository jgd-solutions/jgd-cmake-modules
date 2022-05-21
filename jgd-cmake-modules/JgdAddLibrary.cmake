include_guard()

include(JgdParseArguments)
include(JgdFileNaming)
include(JgdTargetNaming)
include(JgdSeparateList)
include(JgdCanonicalStructure)
include(JgdDefaultCompileOptions)
include(JgdHeaderFileSet)
include(GenerateExportHeader)

function(jgd_add_library)
  jgd_parse_arguments(
    ONE_VALUE_KEYWORDS
    "COMPONENT;NAME;TYPE;OUT_TARGET_NAME"
    MULTI_VALUE_KEYWORDS
    "INTERFACE_HEADERS;PUBLIC_HEADERS;PRIVATE_HEADERS;SOURCES"
    REQUIRES_ANY
    "INTERFACE_HEADERS;PUBLIC_HEADERS;PRIVATE_HEADERS;SOURCES"
    ARGUMENTS "${ARGN}")

  # Set library component
  if (DEFINED ARGS_COMPONENT AND NOT ARGS_COMPONENT STREQUAL PROJECT_NAME)
    set(comp_arg COMPONENT ${ARGS_COMPONENT})
    set(comp_err_msg "component (${ARGS_COMPONENT}) ")
  else()
    unset(comp_arg)
    unset(comp_err_msg)
  endif ()

  # == Usage Guards ==

  # ensure sources are provided appropriately
  if (ARGS_TYPE STREQUAL "INTERFACE")
    if (DEFINED ARGS_SOURCES OR DEFINED ARGS_PUBLIC_HEADERS OR DEFINED ARGS_PRIVATE_HEADERS)
      message(FATAL_ERROR "Interface libraries can only be added with INTERFACE_HEADERS")
    endif ()
  elseif (NOT DEFINED ARGS_SOURCES)
    message(FATAL_ERROR "SOURCES must be provided for non-interface libraries")
  endif ()

  # ensure library is created in the appropriate canonical directory
  jgd_canonical_lib_subdir(${comp_arg} OUT_VAR canonical_dir)
  if (NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL canonical_dir)
    message(
      FATAL_ERROR
      "Creating a ${comp_err_msg}library for project ${PROJECT_NAME} must be "
      "done in the canonical directory ${canonical_dir}.")
  endif ()

  # verify file naming
  jgd_separate_list(
    IN_LIST "${ARGS_SOURCES}"
    REGEX "${JGD_SOURCE_REGEX}"
    TRANSFORM "FILENAME"
    OUT_UNMATCHED incorrectly_named)
  if (incorrectly_named)
    message(
      FATAL_ERROR
      "Provided source files do not match the regex for library sources, "
      "${regex}: ${incorrectly_named}.")
  endif ()

  jgd_separate_list(
    IN_LIST "${ARGS_INTERFACE_HEADERS}" "${ARGS_PUBLIC_HEADERS}" "${ARGS_PRIVATE_HEADERS}"
    REGEX "${JGD_HEADER_REGEX}"
    TRANSFORM "FILENAME"
    OUT_UNMATCHED incorrectly_named)
  if (incorrectly_named)
    message(
      FATAL_ERROR
      "Provided header files do not match the regex for library headers, "
      "${regex}: ${incorrectly_named}.")
  endif ()

  # == Build options related to libraries and this library =================
  # note: locally setting BUILD_SHARED_LIBS has scope constrained to func

  if (NOT DEFINED ARGS_TYPE)
    # commonly used (so it's build-wide) build shared option
    option(BUILD_SHARED_LIBS "Dictates if libraries with unspecified types should be built shared." OFF)

    # project specific build shared option
    option(
      ${JGD_PROJECT_PREFIX_NAME}_BUILD_SHARED_LIBS
      "Dictates if libraries with unspecified types should be built shared. Prefixed to only take affect for ${PROJECT_NAME}."
      ${BUILD_SHARED_LIBS})

    # component specific build shared option
    if (DEFINED comp_arg)
      string(TOUPPER ${ARGS_COMPONENT} comp_temp)
      string(REPLACE "-" "_" comp_upper ${comp_temp})
      option(
        ${JGD_PROJECT_PREFIX_NAME}_${comp_upper}_BUILD_SHARED_LIBS
        "Dictates if libraries with unspecified types should be built shared. Prefixed to only take affect for ${ARGS_COMPONENT} of ${PROJECT_NAME}."
        ${${JGD_PROJECT_PREFIX_NAME}_BUILD_SHARED_LIBS})
    endif ()
  endif ()

  # == Library Configuration ==

  # set library type, if provided and supported
  set(lib_type STATIC)
  if (DEFINED ARGS_TYPE)
    set(lib_type ${ARGS_TYPE})
    set(supported_types STATIC SHARED MODULE INTERFACE)
    list(FIND supported_types "${ARGS_TYPE}" supported)
    if (supported EQUAL -1)
      message(
        FATAL_ERROR
        "Unsupported type ${ARGS_TYPE}. ${CMAKE_CURRENT_FUNCTION} must be "
        "called with no type or one of: ${supported_types}")
    endif ()
  elseif (${JGD_PROJECT_PREFIX_NAME}_BUILD_SHARED_LIBS OR ${JGD_PROJECT_PREFIX_NAME}_${comp_upper}_BUILD_SHARED_LIBS)
    set(lib_type SHARED)
  endif ()

  # resolve library names
  if (DEFINED ARGS_NAME)
    set(target_name ${ARGS_NAME})
    set(export_name ${ARGS_NAME})
    set(output_name ${ARGS_NAME})
  else ()
    jgd_library_naming(
      ${comp_arg}
      OUT_TARGET_NAME
      target_name
      OUT_EXPORT_NAME
      export_name
      OUT_OUTPUT_NAME
      output_name)
  endif ()

  if (DEFINED ARGS_OUT_TARGET_NAME)
    set(${ARGS_OUT_TARGET_NAME} ${target_name} PARENT_SCOPE)
  endif ()

  # == Create Library Target ==

  add_library("${target_name}" ${lib_type} ${ARGS_SOURCES})
  add_library(${PROJECT_NAME}::${export_name} ALIAS ${target_name})

  # == Generate an export header ==

  set(base_name ${JGD_PROJECT_PREFIX_NAME})
  if (DEFINED comp_arg)
    string(APPEND base_name "_${comp_upper}")
  endif ()

  generate_export_header(
    ${target_name}
    BASE_NAME ${base_name}
    EXPORT_FILE_NAME
    "export_macros.hpp")

  # == Set Target Properties ==

  # custom component property
  if (DEFINED comp_arg)
    set_target_properties(${target_name} PROPERTIES ${comp_arg})
  endif ()

  # header properties
  if (DEFINED ARGS_INTERFACE_HEADERS)
    jgd_header_file_set(INTERFACE TARGET ${target_name} HEADERS "${ARGS_INTERFACE_HEADERS}")
  elseif (DEFINED ARGS_PRIVATE_HEADERS)
    jgd_header_file_set(PRIVATE TARGET ${target_name} HEADERS "${ARGS_PRIVATE_HEADERS}")
  endif ()
  jgd_header_file_set(PUBLIC TARGET ${target_name}
    HEADERS "${ARGS_PUBLIC_HEADERS}" "${CMAKE_CURRENT_BINARY_DIR}/export_macros.hpp")

  # common properties
  set_target_properties(
    ${target_name}
    PROPERTIES OUTPUT_NAME ${output_name}
    PREFIX ""
    EXPORT_NAME ${export_name}
    COMPILE_OPTIONS "${JGD_DEFAULT_COMPILE_OPTIONS}")

  # shared library versioning
  if (PROJECT_VERSION AND lib_type STREQUAL "SHARED")
    set_target_properties(
      ${target_name} PROPERTIES VERSION ${PROJECT_VERSION}
      SOVERSION ${PROJECT_VERSION_MAJOR})
  endif ()
endfunction()
