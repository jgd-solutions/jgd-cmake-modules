include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdDefaultTargetProps)
include(JgdCanonicalStructure)

#
# Creates a library called LIBRARY, of the specified TYPE, with the default
# target properties, specified in JgdDefaultTargetProps. Additionally, an ALIAS
# library for use within the build tree. Lastly, if the library is prefixed with
# "lib", is STATIC or SHARED, and "lib" is the library's PREFIX property, "lib"
# is stripped from the library's output name.
#
# Arguments:
#
# LIBRARY: one-value arg; the name of the library to generate.
#
# TYPE: one-value arg; the type of the library to generate. One of STATIC,
# SHARED, OBJECT, INTERFACE. Optional - if omitted, the generated library will
# be one of STATIC or SHARED, determined by CMake.
#
# COMPONENT: one-value arg; the component in which the added library belongs.
# Used to resolve appropriate include directories. Optional, if not part of a
# component.
#
# SOURCES: multi value arg; the sources to create LIBRARY from.
#
function(jgd_add_default_library)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "LIBRARY;TYPE;COMPONENT"
                      MULTI_VALUE_KEYWORDS "SOURCES" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "LIBRARY;SOURCES")

  foreach(source ${ARGS_SOURCES})
    set(regex "${JGD_HEADER_REGEX}|${JGD_SOURCE_REGEX}")
    string(REGEX MATCH "${regex}" matched "${source}")
    if(NOT matched)
      message(FATAL_ERROR "Provided source file, ${source}, does not match the"
                          "regex for library sources, ${regex}.")
    endif()
  endforeach()

  set(type)
  if(ARGS_TYPE)
    set(supported_types STATIC SHARED OBJECT INTERFACE)
    list(FIND supported_types "${ARGS_TYPE}" supported)
    if(supported EQUAL -1)
      message(
        FATAL_ERROR
          "Unsupported type ${ARGS_TYPE}. ${CMAKE_CURRENT_FUNCTION} must be "
          "called with one of: ${supported_types}")
    endif()
    set(type "${ARGS_TYPE}")
  endif()

  if("${type}" STREQUAL "INTERFACE")
    add_library("${ARGS_LIBRARY}" INTERFACE)
  else()
    add_library("${ARGS_LIBRARY}" ${type} SOURCES "${ARGS_SOURCES}")
  endif()

  # alias so library can be used as component inside build tree (tests)
  add_library(${PROJECT_NAME}::${ARGS_LIBRARY} ALIAS ${ARGS_LIBRARY})

  if("${type}" MATCHES "STATIC|SHARED")
    get_target_property(prefix "${ARGS_LIBRARY}" PREFIX)
    if("${prefix}" STREQUAL "${JGD_LIB_PREFIX}")
      string(REGEX REPLACE "^${JGD_LIB_PREFIX}" "" outname "${ARGS_LIBRARY}")
      set_target_properties("${ARGS_LIBRARY}" PROPERTIES OUTPUT_NAME ${outname})
    endif()
  endif()

  set(include_access "PUBLIC")
  if("${type}" STREQUAL "INTERFACE")
    set(include_access "INTERFACE")
  else()
    target_compile_options("${ARGS_LIBRARY}"
                           PRIVATE ${JGD_DEFAULT_COMPILE_OPTIONS})
  endif()

  set(comp_arg)
  if(ARGS_COMPONENT)
    set(comp_arg "COMPONENT ${ARGS_COMPONENT}")
  endif()
  jgd_default_include_dir(BUILD_INTERFACE ${comp_arg} OUT_VAR include_dir)
  target_include_directories("${ARGS_LIBRARY}" ${include_access} ${include_dir})
endfunction()
