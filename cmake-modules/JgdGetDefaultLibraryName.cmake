include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdCanonicalStructure)

#
# Gets the default library name for a library built by PROJECT_NAME and of the
# provided COMPONENT. The library name will be
# <JGD_LIB_PREFIX><name>[-COMPONENT], where 'name' is PROJECT_NAME with any
# leading JGD_LIB_PREFIX removed. In the situation that PROJECT_NAME starts with
# JGD_LIB_PREFIX and a COMPONENT is provided, the generated name will then be
# <COMPONENT>.
#
# Ex. 1.1: PROJECT_NAME=libproj -> libproj Ex 1.2: PROJECT_NAME=proj -> libproj
# Ex 1.3: PROJECT_NAME=proj COMPONENT=core -> libproj-core Ex 2:
# PROJECT_NAME=libproj COMPONENT=core -> core.
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
function(jgd_get_default_library_name)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "COMPONENT;OUT_VAR" ARGUMENTS
                      "${ARGN}")
  jgd_validate_arguments(KEYWORDS OUT_VAR)
  if(ARGS_COMPONENT AND NOT "${ARGS_COMPONENT}" STREQUAL "${PROJECT_NAME}")
    set(component "${ARGS_COMPONENT}")
  endif()

  # Basic name without considering component
  string(REGEX REPLACE "^${JGD_LIB_PREFIX}" "" no_prefix ${PROJECT_NAME})
  set(library "${JGD_LIB_PREFIX}${no_prefix}")

  # Append component or override with component
  if(component)
    if(${no_prefix} STREQUAL ${PROJECT_NAME})
      string(APPEND library "-${component}")
    else()
      set(library "${component}")
    endif()
  endif()

  # Set result
  set(${ARGS_OUT_VAR}
      ${library}
      PARENT_SCOPE)
endfunction()
