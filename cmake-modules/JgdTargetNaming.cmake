include_guard()

include(JgdParseArguments)
include(JgdCanonicalStructure)

#
# Sets the output variable specified by the OUT_* arguments to default,
# consistent, unique library names that libraries can use to initialize their
# properties.
#
# OUT_TARGET_NAME's variable specifies the library target name to use within
# CMake commands; it will be <PROJECT_NAME>_<JGD_LIB_PREFIX><name>[-COMPONENT].
# OUT_EXPORT_NAME's variable specifies the exported target name that consumers
# will use; it will be <JGD_LIB_PREFIX><name>, or <COMPONENT> if COMPONENT is
# provided and PROJECT_NAME already starts with JGD_LIB_PREFIX.
# OUT_OUTPUT_NAME's variable specifies the name of the built library on disk,
# which will be <JGD_LIB_PREFIX><name>[-COMPONENT]. For each library name,
# 'name' is the PROJECT_NAME with any leading JGD_LIB_PREFIX stripped.
#
# The target name is prefixed with the project name to avoid conflicts with
# other projects when dependencies are added as subdirectories, for all target
# names in a CMake build must be unique. The exported name doesn't have this, as
# the target should be exported with the namespace prefix '<PROJECT_NAME>::'.
#
# Arguments:
#
# COMPONENT: one-value arg; the component of the project that the library of the
# generated name constitutes. A COMPONENT that matches the PROJECT_NAME will be
# ignored. Optional.
#
# OUT_TARGET_NAME: one-value arg; the name of the variable that will store the
# library target name. Add a library with this name.
#
# OUT_EXPORT_NAME: one-value arg; the name of the variable that will store the
# library's export name. Associated to the library's EXPORT_NAME property.
#
# OUT_OUTPUT_NAME: one-value arg; the name of the variable that will store the
# library's output name. Associated to the library's OUTPUT_NAME property.
#
function(jgd_library_naming)
  jgd_parse_arguments(
    ONE_VALUE_KEYWORDS
    "COMPONENT"
    "OUT_TARGET_NAME"
    "OUT_EXPORT_NAME"
    "OUT_OUTPUT_NAME"
    REQUIRES_ANY
    "OUT_TARGET_NAME"
    "OUT_EXPORT_NAME"
    "OUT_OUTPUT_NAME"
    ARGUMENTS
    "${ARGN}")

  # Resolve component
  if(DEFINED ARGS_COMPONENT AND NOT ARGS_COMPONENT STREQUAL PROJECT_NAME)
    set(component ${ARGS_COMPONENT})
  endif()

  # Base name upon which library names will be derived
  string(REGEX REPLACE "^${JGD_LIB_PREFIX}" "" no_prefix ${PROJECT_NAME})
  set(base_name "${JGD_LIB_PREFIX}${no_prefix}")
  if(DEFINED component)
    string(APPEND base_name "-${component}")
  endif()

  # Export name
  if(DEFINED ARGS_OUT_EXPORT_NAME)
    # there's a component and the project starts with JGD_LIB_PREFIX
    if(DEFINED component AND NOT ${no_prefix} STREQUAL ${PROJECT_NAME})
      set(${ARGS_OUT_EXPORT_NAME}
          ${component}
          PARENT_SCOPE)
    else()
      set(${ARGS_OUT_EXPORT_NAME}
          ${base_name}
          PARENT_SCOPE)
    endif()
  endif()

  # Output name
  if(DEFINED ARGS_OUT_OUTPUT_NAME)
    set(${ARGS_OUT_OUTPUT_NAME}
        ${base_name}
        PARENT_SCOPE)
  endif()

  # Target name
  if(DEFINED ARGS_OUT_TARGET_NAME)
    # prepend project name to avoid possible conflicts if added as subdirectory
    set(${ARGS_OUT_VAR}
        ${PROJECT_NAME}_${base_name}
        PARENT_SCOPE)
  endif()
endfunction()

#
# Sets the output variable specified by the OUT_* arguments to default,
# consistent, unique executable names that executables can use to initialize
# their properties. As a note, it's rare for an executable to be a component or
# be exported.
#
# OUT_TARGET_NAME's variable specifies the executable target name to use within
# CMake commands; it will be <PROJECT_NAME>_<name>[-COMPONENT].
# OUT_EXPORT_NAME's variable specifies the exported target name that consumers
# will use; it will be <name>[-COMPONENT], or <COMPONENT> if COMPONENT is
# provided and PROJECT_NAME doesn't start with JGD_LIB_PREFIX. OUT_OUTPUT_NAME's
# variable specifies the name of the built executable on disk, which will be
# <name>[-COMPONENT]. For each executable name, 'name' is the PROJECT_NAME with
# any leading JGD_LIB_PREFIX stripped.
#
# The target name is prefixed with the project name to avoid conflicts with
# other projects when dependencies are added as subdirectories, for all target
# names in a CMake build must be unique. The exported name doesn't have this, as
# the target should be exported with the namespace prefix '<PROJECT_NAME>::'.
#
# Arguments:
#
# COMPONENT: one-value arg; the component of the project that the executable of
# the generated name constitutes. A COMPONENT that matches the PROJECT_NAME will
# be ignored. Optional.
#
# OUT_TARGET_NAME: one-value arg; the name of the variable that will store the
# executable target name. Add a executable with this name.
#
# OUT_EXPORT_NAME: one-value arg; the name of the variable that will store the
# executable's export name. Associated to the executable's EXPORT_NAME property.
#
# OUT_OUTPUT_NAME: one-value arg; the name of the variable that will store the
# executable's output name. Associated to the executable's OUTPUT_NAME property.
#
function(jgd_executable_naming)
  jgd_parse_arguments(
    ONE_VALUE_KEYWORDS
    "COMPONENT"
    "OUT_TARGET_NAME"
    "OUT_EXPORT_NAME"
    "OUT_OUTPUT_NAME"
    REQUIRES_ANY
    "OUT_TARGET_NAME"
    "OUT_EXPORT_NAME"
    "OUT_OUTPUT_NAME"
    ARGUMENTS
    "${ARGN}")

  # Resolve component
  if(DEFINED ARGS_COMPONENT AND NOT ARGS_COMPONENT STREQUAL PROJECT_NAME)
    set(component ${ARGS_COMPONENT})
  endif()

  # Base name upon which executable names will be derived
  string(REGEX REPLACE "^${JGD_LIB_PREFIX}" "" no_prefix ${PROJECT_NAME})
  set(base_name ${no_prefix})
  if(DEFINED component)
    string(APPEND base_name "-${component}")
  endif()

  # Export name
  if(DEFINED ARGS_OUT_EXPORT_NAME)
    # there's a component and the project doesn't start with JGD_LIB_PREFIX
    if(DEFINED component AND ${no_prefix} STREQUAL ${PROJECT_NAME})
      set(${ARGS_OUT_EXPORT_NAME}
          ${component}
          PARENT_SCOPE)
    else()
      set(${ARGS_OUT_EXPORT_NAME}
          ${base_name}
          PARENT_SCOPE)
    endif()
  endif()

  # Output name
  if(DEFINED ARGS_OUT_OUTPUT_NAME)
    set(${ARGS_OUT_OUTPUT_NAME}
        ${base_name}
        PARENT_SCOPE)
  endif()

  # Target name
  if(DEFINED ARGS_OUT_TARGET_NAME)
    # prepend project name to avoid possible conflicts if added as subdirectory
    set(${ARGS_OUT_VAR}
        ${PROJECT_NAME}_${base_name}
        PARENT_SCOPE)
  endif()
endfunction()
