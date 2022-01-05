include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdCanonicalStructure)

#
# Private macro to the module. After checking that it's a directory, appends the
# given SUBDIR to the 'subdirs_added' variable, and unless NO_ADD_SUBDIRECTORY
# is specified, adds the given SUBDIR as a subdirectory.
#
# Arguments:
#
# NO_ADD_SUBDIRECTORY: option; specifies that SUBDIR should not be added as a
# subdirectory.
#
# SUBDIR: one-value arg; the path of the subdirectory to add to 'subdirs_added'
# and, optionally add as a subdirectory with CMake's add_subdirectory() command.
# Can be absolute or relative to the current directory, as defined by
# add_subdirectory().
#
macro(_ADD_SUBDIR_CHECK)
  jgd_parse_arguments(OPTIONS "NO_ADD_SUBDIRECTORY" ONE_VALUE_KEYWORDS "SUBDIR"
                      ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "SUBDIR")

  if(IS_DIRECTORY "${ARGS_SUBDIR}")
    list(APPEND subdirs_added "${ARGS_SUBDIR}")
    if(NOT ARGS_NO_ADD_SUBDIRECTORY)
      message(DEBUG "${CMAKE_CURRENT_FUNCTION}: Adding directory "
              "${ARGS_SUBDIR} to project ${PROJECT_NAME}")
      add_subdirectory("${ARGS_SUBDIR}")
    endif()
  endif()
endmacro()

#
# Adds subdirectories following JGD's project layout conventions, which are the
# canonical project layout conventions. These canonical subdirectories are
# provided by functions in  JgdCanonicalStructure. That is, if they exists, the
# subdirectories ./<PROJECT_NAME>-<component>/<PROJECT_NAME>/<component>, if
# COMPONENTS are provided, or just ./<JGD_LIB_PREFIX><name>, and ./<name> will
# be added. Here, 'component' is an entry of COMPONENTS, and 'name' is
# PROJECT_NAME with JGD_LIB_PREFIX stripped. The variable JGD_CURRENT_COMPONENT
# will be set to 'component' before adding each component subdirectory.
#
# This function is not meant as a complete replacement for add_subdirectory(),
# but instead makes adding the project's default directories, following the
# layout conventions, easier.
#
# Arguments:
#
# COMPONENTS: multi-value arg; list of components that the PROJECT encapsulates.
# Optional and shouldn't be used if the project doesn't contain any components.
# Components that match the PROJECT_NAME will be ignored.
#
function(jgd_add_default_source_subdirectories)
  jgd_parse_arguments(
    OPTIONS
    "NO_ADD_SUBDIRECTORY"
    ON_VALUE_KEYWORDS
    "OUT_VAR"
    MULTI_VALUE_KEYWORDS
    "COMPONENTS"
    ARGUMENTS
    "${ARGN}")
  jgd_validate_arguments()

  # more argument validation
  if(ARGS_NO_ADD_SUBDIRECTORY AND NOT ARGS_OUT_VAR)
    messag(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} was called without OUT_VAR "
           "and with NO_ADD_SUBDIRECTORY set, rendering the function useless.")
  endif()

  # Setup
  set(subdirs_added)
  list(REMOVE_ITEM ARGS_COMPONENTS "${PROJECT_NAME}")

  if(DEFINED ARGS_COMPONENTS)
    # add all components' subdirectories
    foreach(component ${ARGS_COMPONENTS})
      list(LENGTH subdirs_added old_len)

      jgd_canonical_component_subdir(COMPONENT "${component}" OUT_VAR
                                     subdir_path)
      set(JGD_CURRENT_COMPONENT "${component}")
      _add_subdir_check(${ARGS_NO_ADD_SUBDIRECTORY} SUBDIR "${subdir_path}")
      unset(JGD_CURRENT_COMPONENT)

      list(LENGTH subdirs_added new_len)
      if(${new_len} EQUAL ${old_len})
        message(
          FATAL_ERROR
            "${CMAKE_CURRENT_FUNCTION} could not add subdirectory "
            "${subdir_path} for component ${component} or project "
            "${PROJECT_NAME}. Directory does not exist.")
      endif()
    endforeach()
  else()
    # add single library subdirectory, if it exists
    jgd_canonical_lib_subdir(OUT_VAR lib_subdir)
    _add_subdir_check(${ARGS_NO_ADD_SUBDIRECTORY} SUBDIR "${lib_subdir}")
  endif()

  # add executable source subdirectory, if it exists
  jgd_canonical_exec_subdir(OUT_VAR exec_subdir)
  _add_subdir_check(${ARGS_NO_ADD_SUBDIRECTORY} SUBDIR "${exec_subdir}")

  # Ensure at least one sub directory was added
  if(NOT subdirs_added)
    message(
      FATAL_ERROR
        "${CMAKE_CURRENT_FUNCTION} could not add any subdirectories for "
        "project ${PROJECT_NAME}. No COMPONENTS were provided, and neither the "
        "library subdirectory, ${lib_subdir}, nor the executable subdirectory, "
        "${exec_subdir}, exist.")
  endif()

  # Set result variable
  if(ARGS_OUT_VAR)
    set(${ARGS_OUT_VAR}
        "${subdirs_added}"
        PARENT_SCOPE)
  endif()
endfunction()
