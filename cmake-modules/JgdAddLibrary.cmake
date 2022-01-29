include_guard()

include(JgdParseArguments)
include(JgdFileNaming)
include(JgdTargetNaming)
include(JgdSeparateList)
include(JgdCanonicalStructure)
include(JgdDefaultCompileOptions)
include(GenerateExportHeader)

define_property(
  TARGET
  PROPERTY COMPONENT
  BRIEF_DOCS "Component name."
  FULL_DOCS
    "The name of a library or executable component that the target represents.")

function(jgd_add_library)
  jgd_parse_arguments(
    ONE_VALUE_KEYWORDS
    "COMPONENT;LIBRARY;TYPE"
    MULTI_VALUE_KEYWORDS
    "SOURCES"
    REQUIRES_ALL
    "SOURCES"
    ARGUMENTS
    "${ARGN}")

  # Set library component
  if(ARGS_COMPONENT AND NOT ARGS_COMPONENT STREQUAL PROJECT_NAME)
    set(comp_arg COMPONENT ${ARGS_COMPONENT})
    set_property(TARGET PROPERTY COMPONENT ${ARGS_COMPONENT})
  endif()

  # Ensure library is created in the appropriate canonical directory
  if(DEFINED comp_arg)
    jgd_canonical_lib_component_subdir(COMPONENT ${ARGS_COMPONENT} OUT_VAR
                                       canonical_dir)
    set(comp_err_msg "component (${ARGS_COMPONENT}) ")
  else()
    jgd_canonical_lib_subdir(OUT_VAR canonical_dir)
  endif()
  if(NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL canonical_dir)
    message(
      FATAL_ERROR
        "Creating a ${comp_err_msg}library for project ${PROJECT_NAME} must be "
        "done in the canonical directory ${canonical_dir}.")
  endif()

  # Verify source naming
  set(regex "${JGD_HEADER_REGEX}|${JGD_SOURCE_REGEX}")
  jgd_separate_list(IN_LIST "${ARGS_SOURCES}" TRANSFORM "FILENAME"
                    OUT_UNMATCHED incorrectly_named)
  if(incorrectly_named)
    message(
      FATAL_ERROR
        "Provided source files do not match the regex for library sources, "
        "${regex}: ${incorrectly_named}.")
  endif()

  # Override library type with TYPE, if provided and supported
  set(lib_type "")
  if(ARGS_TYPE)
    set(supported_types STATIC SHARED MODULE OBJECT INTERFACE)
    list(FIND supported_types "${ARGS_TYPE}" supported)
    if(supported EQUAL -1)
      message(
        FATAL_ERROR
          "Unsupported type ${ARGS_TYPE}. ${CMAKE_CURRENT_FUNCTION} must be "
          "called with one of: ${supported_types}")
    endif()
    set(lib_type "${ARGS_TYPE}")
  else()

    # Create build shared options related to libraries and this library.
    option(BUILD_SHARED_LIBS "Dictates if libraries with unspecified types "
           "should be built shared." OFF)
    option(
      ${JGD_PROJECT_PREFIX_NAME}_BUILD_SHARED_LIBS
      "Dictates if libraries with unspecified types should be built shared. "
      "Prefixed to only take affect for ${PROJECT_NAME}." ${BUILD_SHARED_LIBS})

    set(BUILD_SHARED_LIBS ${JGD_PROJECT_PREFIX_NAME}_BUILD_SHARED_LIBS})

    if(DEFINED comp_arg)
      string(TOUPPER ${ARGS_COMPONENT} comp_temp)
      string(REPLACE "-" "_" ${comp_temp} comp_upper)
      option(
        ${JGD_PROJECT_PREFIX_NAME}_${comp_upper}_BUILD_SHARED_LIBS
        "Dictates if libraries with unspecified types should be built shared. "
        "Prefixed to only take affect for ${PROJECT_NAME}."
        ${JGD_PROJECT_PREFIX_NAME}_BUILD_SHARED_LIBS)

      set(BUILD_SHARED_LIBS
          ${JGD_PROJECT_PREFIX_NAME}_${comp_upper}_BUILD_SHARED_LIBS)
    endif()
  endif()

  # Library names
  if(ARGS_LIBRARY)
    set(target_name "${ARGS_LIBRARY}")
    set(export_name ${library})
    set(output_name ${library})
  else()
    jgd_library_target_name(${comp_arg} OUT_VAR target_name)
    string(REPLACE "${PROJECT_NAME}_" "" export_name "${library}")
    string(REGEX REPLACE "^${JGD_LIB_PREFIX}" "" output_name "${export_name}")
  endif()

  # Create library target
  if(lib_type STREQUAL "INTERFACE")
    add_library("${library}" INTERFACE)
  else()
    add_library("${library}" ${lib_type} "${ARGS_SOURCES}")
  endif()
  add_library(${PROJECT_NAME}::${export_name} ALIAS ${target_name})

  # Set the target properties
  set_target_properties(
    ${target_name}
    PROPERTIES OUTPUT_NAME ${output_name}
               PREFIX ${JGD_LIB_PREFIX}
               EXPORT_NAME ${export_name}
               COMPILE_OPTIONS ${JGD_DEFAULT_COMPILE_OPTIONS})

  if(PROJECT_VERSION)
    set_target_properties(
      ${target_name} PROPERTIES VERSION ${PROJECT_VERSION}
                                SOVERSION ${PROJECT_VERSION_MAJOR})
  endif()

  # Export header
  string(REPLACE "-" "_" export_file_name "${export_name}_export.hpp")
  generate_export_header(
    ${target_name}
    PREFIX_NAME
    ${JGD_PROJECT_PREFIX_NAME}
    BASE_NAME
    ${export_name}
    EXPORT_FILE_NAME
    ${export_file_name})

endfunction()
