include_guard()

include(JgdParseArguments)
include(JgdFileNaming)
include(JgdTargetNaming)
include(JgdSeparateList)
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

  # Create Library
  add_library(${target_name})
  add_library(${PROJECT_NAME}::${export_name} ALIAS ${target_name})
  set_target_properties(
    ${target_name}
    PROPERTIES OUTPUT_NAME ${output_name}
               PREFIX ${JGD_LIB_PREFIX}
               EXPORT_NAME ${export_name})

  if(PROJECT_VERSION)
    set_target_properties(
      ${target_name} PROPERTIES VERSION ${PROJECT_VERSION}
                                SOVERSION ${PROJECT_VERSION_MAJOR})
  endif()

  # generate_export_header(${library} PREFIX_NAME ${JGD_PROJECT_PREFIX_NAME}
  # EXPORT_FILE_NAME .)

  # compile flags? include dirs?

endfunction()
