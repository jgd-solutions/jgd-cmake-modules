include_guard()

include(JgdParseArguments)
include(JgdCanonicalStructure)

#
# Private macro to the module. After checking that it's a directory, appends the
# given SUBDIR to the 'subdirs_added' variable, and if ADD_SUBDIRS is specified,
# adds the given SUBDIR as a subdirectory.
#
# Arguments:
#
# ADD_SUBDIRS: option; specifies that SUBDIR should be added as a subdirectory.
#
# SUBDIR: one-value arg; the path of the subdirectory to add to 'subdirs_added'
# and, optionally add as a subdirectory with CMake's add_subdirectory() command.
# Can be absolute or relative to the current directory, as defined by
# add_subdirectory().
#
macro(_JGD_CHECK_ADD_SUBDIR)
  jgd_parse_arguments(
    OPTIONS
    "ADD_SUBDIRS"
    ONE_VALUE_KEYWORDS
    "SUBDIR"
    REQUIRES_ALL
    "SUBDIR"
    ARGUMENTS
    "${ARGN}")

  if(IS_DIRECTORY "${ARGS_SUBDIR}")
    list(APPEND subdirs_added "${ARGS_SUBDIR}")
    if(ARGS_ADD_SUBDIRS)
      message(DEBUG "${CMAKE_CURRENT_FUNCTION}: Adding directory "
              "${ARGS_SUBDIR} to project ${PROJECT_NAME}")
      add_subdirectory("${ARGS_SUBDIR}")
    endif()
  endif()
endmacro()

#
# Provides subdirectories following JGD's project layout conventions, which are
# the canonical project layout conventions. These canonical subdirectories are
# provided by functions in  JgdCanonicalStructure. That is, the executable,
# library or library component subdirectories will be added, if they exist. The
# variable JGD_CURRENT_COMPONENT will be set to the component before adding each
# component's subdirectory.
#
# Arguments:
#
# LIB_COMPONENTS: multi-value arg; list of library components that the PROJECT
# encapsulates.  Optional and shouldn't be used if the project doesn't contain
# any library components. Components that match the PROJECT_NAME will be
# ignored.
#
# ADD_SUBDIRS: one-value arg; when defined, will cause the function to add the
# source subdirectories as project subdirectories with CMake's
# add_subdirectory() command, in addition to adding them to the variable
# specified by OUT_VAR.
#
# OUT_VAR: one-value arg; the name of the list that will contain the added
# subdirectories. This list will be populated regardless of if the ADD_SUBDIRS
# was provided, or not.
#
function(jgd_source_subdirectories)
  jgd_parse_arguments(
    OPTIONS
    "ADD_SUBDIRS"
    ON_VALUE_KEYWORDS
    "OUT_VAR"
    MULTI_VALUE_KEYWORDS
    "LIB_COMPONENTS"
    REQUIRES_ANY
    "ADD_SUBDIRS;OUT_VAR"
    ARGUMENTS
    "${ARGN}")

  # Setup
  set(subdirs_added)
  list(REMOVE_ITEM ARGS_LIB_COMPONENTS "${PROJECT_NAME}")

  if(ADD_SUBDIRS)
    set(add_subdirs_arg ADD_SUBDIRS)
  endif()

  # Add Subdirs
  if(DEFINED ARGS_LIB_COMPONENTS)
    # add all components' subdirectories
    foreach(component ${ARGS_LIB_COMPONENTS})
      list(LENGTH subdirs_added old_len)
      jgd_canonical_lib_component_subdir(COMPONENT "${component}" OUT_VAR
                                         subdir_path)
      set(JGD_CURRENT_COMPONENT "${component}")
      _jgd_check_add_subdir(${add_subdirs_arg} SUBDIR "${subdir_path}")
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
    _jgd_check_add_subdir(${add_subdirs_arg} SUBDIR "${lib_subdir}")
  endif()

  # add executable source subdirectory, if it exists
  jgd_canonical_exec_subdir(OUT_VAR exec_subdir)
  _jgd_check_add_subdir(${add_subdirs_arg} SUBDIR "${exec_subdir}")

  # Ensure at least one sub directory was added
  if(NOT subdirs_added)
    message(
      FATAL_ERROR
        "${CMAKE_CURRENT_FUNCTION} could not add any subdirectories for "
        "project ${PROJECT_NAME}. No LIB_COMPONENTS were provided, and neither the "
        "library subdirectory, ${lib_subdir}, nor the executable subdirectory, "
        "${exec_subdir}, exist.")
  endif()

  # Set result variable
  if(DEFINED ARGS_OUT_VAR)
    set(${ARGS_OUT_VAR}
        "${subdirs_added}"
        PARENT_SCOPE)
  endif()
endfunction()
