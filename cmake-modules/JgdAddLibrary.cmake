include_guard()

include(JgdParseArguments)
include(JgdFileNaming)
include(JgdTargetNaming)
include(JgdSeparateList)
include(JgdDefaultCompileOptions)
include(GenerateExportHeader)

# create build_shared option for component, if it's a component

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

  if(ARGS_COMPONENT AND NOT ARGS_COMPONENT STREQUAL PROJECT_NAME)
    set(comp_arg COMPONENT ${ARGS_COMPONENT})
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

  # generate_export_header(${library} PREFIX_NAME ${JGD_PROJECT_PREFIX_NAME}
  # EXPORT_FILE_NAME .)

  # compile flags? include dirs?
  target_compile_options(${target_name})

endfunction()

# PREFIX_BUILD_SHARED <-BUILD_SHARED_LIBS # create only if type isn't provided,
# default to BUILD_SHARED_LIBS PREFIX_COMPONENT_BUILD_SHARED <-
# PREFIX_BUILD_SHARED # create only if type isn't provided and component is
# provided
