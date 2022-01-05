include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdDefaultTargetProps)
include(JgdCanonicalStructure)
include(JgdFileNaming)

#
# Creates a library with a generated name and the default target properties
# defined in JgdDefaultTargetProps. These include the target's output name,
# compile options, and include directories.
#
# The generated library name will be <JGD_LIB_PREFIX><name>[-COMPONENT], where
# 'name' is PROJECT_NAME with any leading JGD_LIB_PREFIX removed. In the
# situation that PROJECT_NAME starts with JGD_LIB_PREFIX and a COMPONENT is
# provided, the generated name will then be <COMPONENT>. In both cases, 'name'
# is PROJECT. Ex. 1.1: PROJECT_NAME=libproj -> libproj Ex 1.2: PROJECT_NAME=proj
# -> libproj Ex 1.3: PROJECT_NAME=proj COMPONENT=core -> libproj-core Ex 2:
# PROJECT_NAME=libproj COMPONENT=core -> core.
#
# Additionally, an ALIAS library is created for use within the build tree
# (testing), regardless of if COMPONENT is provided. The alias will be
# <PROJECT_NAME>::<lib>, where 'lib' is either the generated library name or
# LIBRARY, if overridden.
#
# The libraries OUTPUT_NAME and PREFIX properties will only be set if the it is
# a STATIC or SHARED library, which will be <name>[-COMPONENT] and
# JGD_LIB_PREFIX, respectfully. This forms <JGD_LIB_PREFIX><name>[-COMPONENT] on
# disk.
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
    set(comp_arg COMPONENT ${component})
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
  if(ARGS_LIBRARY)
    set(library "${ARGS_LIBRARY}")
  else()
    string(REGEX REPLACE "^${JGD_LIB_PREFIX}" "" no_prefix ${PROJECT_NAME})
    set(library "${JGD_LIB_PREFIX}${no_prefix}")

    if(component)
      if(${no_prefix} STREQUAL ${PROJECT_NAME})
        string(APPEND library "-${component}")
      else()
        set(library "${component}")
      endif()
    endif()
  endif()

  # Override library type with TYPE, if provided and supported
  set(lib_type)
  if(ARGS_TYPE)
    set(supported_types STATIC SHARED OBJECT INTERFACE)
    list(FIND supported_types "${ARGS_TYPE}" supported)
    if(supported EQUAL -1)
      message(
        FATAL_ERROR
          "Unsupported type ${ARGS_TYPE}. ${CMAKE_CURRENT_FUNCTION} must be "
          "called with one of: ${supported_types}")
    endif()
    set(lib_type "${ARGS_TYPE}")
  endif()

  # Add the library with alias
  if("${lib_type}" STREQUAL "INTERFACE")
    add_library("${library}" INTERFACE)
  else()
    add_library("${library}" ${lib_type} "${ARGS_SOURCES}")
  endif()

  add_library(${PROJECT_NAME}::${library} ALIAS ${library})

  # Set default target properties

  # change output name
  if(NOT lib_type OR "${lib_type}" MATCHES "STATIC|SHARED")
    jgd_default_lib_output_name(OUT_VAR out_name ${comp_arg})
    set_target_properties("${library}" PROPERTIES OUTPUT_NAME ${out_name}
                                                  PREFIX ${JGD_LIB_PREFIX})
  endif()

  # compile options
  set(include_access "PUBLIC")
  if("${lib_type}" STREQUAL "INTERFACE")
    set(include_access "INTERFACE")
  else()
    target_compile_options("${library}" PRIVATE ${JGD_DEFAULT_COMPILE_OPTIONS})
  endif()

  # include directories
  jgd_default_include_dirs(BUILD_INTERFACE ${comp_arg} OUT_VAR include_dirs)
  target_include_directories("${library}" ${include_access} "${include_dirs}")
endfunction()
