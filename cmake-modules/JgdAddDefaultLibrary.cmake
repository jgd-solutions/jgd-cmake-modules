include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdDefaultTargetProps)
include(JgdCanonicalStructure)
include(JgdFileNaming)

#
# Creates a library with a generated name and the default target properties
# defined in JgdDefaultTargetProps. The generated name will be
# <JGD_LIB_PREFIX><NAME>[-COMPONENT], where NAME is PROJECT_NAME with any
# JGD_LIB_PREFIX stripped, so all libraries are prefixed by a single
# JGD_LIB_PREFIX. Ex. 1: libproj Ex. 2: libproj-core.
#
# Additionally, an ALIAS library is created for use within the build tree
# (testing), regardless of if COMPONENT is provided. The alias will be
# <PROJECT_NAME>::<LIB>, where LIB is either the generated library name or
# LIBRARY, if overridden. That is, unless PROJECT_NAME starts with
# JGD_LIB_PREFIX and COMPONENT is provied, where the alias will be
# <PROJECT_NAME>::<COMPONENT>. Ex 1. libproj::libproj Ex 2. libproj::core Ex 3.
# proj::libproj Ex 4. proj::libproj-core
#
# Lastly, if the library is prefixed with JGD_LIB_PREFIX, is STATIC or SHARED,
# and JGD_LIB_PREFIX is the same as library's PREFIX property, JGD_LIB_PREFIX is
# stripped from the library's output name, since the PREFIX property will be
# prepended to the output name, automatically.
#
# Arguments:
#
# COMPONENT: one-value arg; the component of the project that the library
# constitutes, if the project is a multi-component project. A COMPONENT that
# matches the PROJECT_NAME will be ignored. Optional.
#
# LIBRARY: one-value arg; the override library name to create. Optional - if
# omitted, a library name will be generated.
#
# TYPE: one-value arg; the type of the library to generate. One of STATIC,
# SHARED, OBJECT, INTERFACE. Optional - if omitted, the generated library will
# be one of STATIC or SHARED, determined by CMake.
#
# SOURCES: multi value arg; the sources to create LIBRARY from.
#
function(jgd_add_default_library)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "COMPONENT;LIBRARY;TYPE"
                      MULTI_VALUE_KEYWORDS "SOURCES" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "SOURCES")
  if(NOT "${ARGS_COMPONENT}" STREQUAL "${PROJECT_NAME}")
    set(component "${ARGS_COMPONENT}")
  endif()

  # Verify source naming
  foreach(source ${ARGS_SOURCES})
    set(regex "${JGD_HEADER_REGEX}|${JGD_SOURCE_REGEX}")
    string(REGEX MATCH "${regex}" matched "${source}")
    if(NOT matched)
      message(FATAL_ERROR "Provided source file, ${source}, does not match the"
                          "regex for library sources, ${regex}.")
    endif()
  endforeach()

  # Generate library name
  string(REGEX REPLACE "^${JGD_LIB_PREFIX}" "" no_prefix ${PROJECT_NAME})
  set(library "${JGD_LIB_PREFIX}${no_prefix}")
  if(ARGS_LIBRARY)
    set(library "${ARGS_LIBRARY}")
  elseif(component)
    string(APPEND library "-${component}")
  endif()

  # Override library type with TYPE, if provided and supported
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

  # Add the library with alias
  if("${type}" STREQUAL "INTERFACE")
    add_library("${library}" INTERFACE)
  else()
    add_library("${library}" ${type} SOURCES "${ARGS_SOURCES}")
  endif()

  set(alias "${PROJECT_NAME}::${library}")
  if((NOT ${no_prefix} STREQUAL ${PROJECT_NAME}) AND component)
    set(alias "${PROJECT_NAME}::${component}")
  endif()
  add_library(${alias} ALIAS ${ARGS_LIBRARY})

  # Change output name
  if("${type}" MATCHES "STATIC|SHARED")
    get_target_property(prefix "${ARGS_LIBRARY}" PREFIX)
    if("${prefix}" STREQUAL "${JGD_LIB_PREFIX}")
      set_target_properties("${ARGS_LIBRARY}" PROPERTIES OUTPUT_NAME
                                                         ${no_prefix})
    endif()
  endif()

  # Set default target properties
  set(include_access "PUBLIC")
  if("${type}" STREQUAL "INTERFACE")
    set(include_access "INTERFACE")
  else()
    target_compile_options("${ARGS_LIBRARY}"
                           PRIVATE ${JGD_DEFAULT_COMPILE_OPTIONS})
  endif()

  set(comp_arg)
  if(component)
    set(comp_arg "COMPONENT ${component}")
  endif()
  jgd_default_include_dirs(BUILD_INTERFACE ${comp_arg} OUT_VAR include_dirs)
  target_include_directories("${ARGS_LIBRARY}" ${include_access}
                             "${include_dirs}")
endfunction()
