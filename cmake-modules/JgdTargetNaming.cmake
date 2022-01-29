include_guard()

include(JgdParseArguments)
include(JgdCanonicalStructure)

#
# Sets the variable specified by OUT_VAR to a default, consistent, unique
# library target name. The name will be <PROJECT_NAME>_lib<name>[-COMPONENT],
# where 'name' is the PROJECT_NAME with any leading JGD_LIB_PREFIX stripped. The
# target name is prefixed with the project name to avoid conflicts with other
# projects when dependencies are added as subdirectories, for all target names
# in a CMake build must be unique.
#
# Arguments:
#
# COMPONENT: one-value arg; the component of the project that the library of the
# generated name constitutes. A COMPONENT that matches the PROJECT_NAME will be
# ignored. Optional.
#
# OUT_VAR: one-value arg; the name of the variable that will store the library
# name
#
function(jgd_library_target_name)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "COMPONENT;OUT_VAR" REQUIRES_ALL
                      "OUT_VAR" ARGUMENTS "${ARGN}")

  # Basic name without considering component
  string(REGEX REPLACE "^${JGD_LIB_PREFIX}" "" no_prefix ${PROJECT_NAME})
  set(library "${JGD_LIB_PREFIX}${no_prefix}")

  # Append component
  if(ARGS_COMPONENT AND NOT ARGS_COMPONENT STREQUAL PROJECT_NAME)
    set(library ${library}-${ARGS_COMPONENT})
  endif()

  # Prepend project name to avoid possible conflicts if added as subdirectory
  set(library ${PROJECT_NAME}_${library})

  # Set result
  set(${ARGS_OUT_VAR}
      ${library}
      PARENT_SCOPE)
endfunction()

#
# Sets the variable specified by OUT_VAR to a default, consistent, unique
# executable target name. The name will be <PROJECT_NAME>_<name>[-COMPONENT],
# where 'name' is the PROJECT_NAME with any leading JGD_LIB_PREFIX stripped. The
# target name is prefixed with the project name to avoid conflicts with other
# projects when dependencies are added as subdirectories, for all target names
# in a CMake build must be unique.
#
# Arguments:
#
# COMPONENT: one-value arg; the component of the project that the executable of
# the generated name constitutes. A COMPONENT that matches the PROJECT_NAME will
# be ignored. Optional.
#
# OUT_VAR: one-value arg; the name of the variable that will store the
# executable name
#
function(jgd_executable_target_name)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "COMPONENT;OUT_VAR" REQUIRES_ALL
                      "OUT_VAR" ARGUMENTS "${ARGN}")

  # Basic name without considering component
  string(REGEX REPLACE "^${JGD_LIB_PREFIX}" "" no_prefix ${PROJECT_NAME})
  set(executable ${no_prefix})

  # Append component
  if(ARGS_COMPONENT AND NOT ARGS_COMPONENT STREQUAL PROJECT_NAME)
    set(executable ${executable}-${ARGS_COMPONENT})
  endif()

  # Prepend project name to avoid possible conflicts if added as subdirectory
  set(executable ${PROJECT_NAME}_${executable})

  # Set result
  set(${ARGS_OUT_VAR}
      ${executable}
      PARENT_SCOPE)
endfunction()
