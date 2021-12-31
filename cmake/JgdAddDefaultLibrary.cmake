include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdDefaultTargetProps)

#
# Creates a library called LIBRARY, of the specified TYPE, with the default
# target properties, specified in JgdDefaultTargetProps. Additionally, an ALIAS
# library (<project-name>::<library-name>) will be created such that other
# internal artifacts can link to the created library as third-parties would.
# Lastly, if the library is prefixed with "lib" and is STATIC or SHARED, "lib"
# is stripped from the library's output name, as "lib" is the default prefix
# added by CMake.
#
# Arguments:
#
# LIBRARY: one value arg; the name of the library to generate.
#
# TYPE: one value arg; the type of the library to generate. One of STATIC,
# SHARED, OBJECT, INTERFACE.
#
# SOURCES: multi value arg; the sources to create LIBRARY from.
#
function(jgd_add_default_library)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "LIBRARY;TYPE" MULTI_VALUE_KEYWORDS
                      "SOURCES" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "LIBRARY;TYPE;SOURCES")

  set(supported_types STATIC SHARED OBJECT INTERFACE)
  list(FIND supported_types "${ARGS_TYPE}" supported)
  if(supported STREQUAL -1)
    message(
      FATAL_ERROR
        "Unsupported type ${ARGS_TYPE}. ${CMAKE_CURRENT_FUNCTION} must be "
        "called with one of: ${supported_types}")
  endif()

  if("${ARGS_TYPE}" STREQUAL "INTERFACE")
    message(STATUS)
    add_library("${ARGS_LIBRARY}" ${ARGS_TYPE})
  else()
    add_library("${ARGS_LIBRARY}" ${ARGS_TYPE} ${sources_keyword}
                                  "${ARGS_SOURCES}")
  endif()

  # alias so library can be used as component inside build tree (tests)
  add_library(${PROJECT_NAME}::${ARGS_LIBRARY} ALIAS ${ARGS_LIBRARY})

  if("${ARGS_TYPE}" STREQUAL "STATIC" OR "${ARGS_TYPE}" STREQUAL "SHARED")
    string(REGEX REPLACE "^lib" "" outname "${ARGS_LIBRARY}")
    set_target_properties("${ARGS_LIBRARY}" PROPERTIES OUTPUT_NAME ${outname})
  endif()

  set(include_access "PUBLIC")
  if("${ARGS_TYPE}" STREQUAL "INTERFACE")
    set(include_access "INTERFACE")
  else()
    target_compile_options(${PROJECT_NAME}
                           PRIVATE ${JGD_DEFAULT_COMPILE_OPTIONS})
  endif()

  target_include_directories("${ARGS_LIBRARY}" ${include_access}
                             ${JGD_DEFAULT_INCLUDE_DIRS})

endfunction()
