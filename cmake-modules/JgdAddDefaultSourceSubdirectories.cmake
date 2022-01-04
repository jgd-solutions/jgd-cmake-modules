include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdCanonicalStructure)

#
# Private macro to the module. Simply adds the given SUBDIR as a subdirectory,
# only after checking that it's a directory, then sets the subdirs_added
# variable TRUE.
#
# Arguments:
#
# SUBDIR: one-value arg; the path of the subdirectory to add with CMake's
# add_subdirectory() command. Can be absolute or relative to the current
# directory, as defined by add_subdirectory().
#
macro(_ADD_SUBDIR_CHECK)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "SUBDIR" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "SUBDIR")
  if(IS_DIRECTORY "${ARGS_SUBDIR}")
    message(DEBUG "${CMAKE_CURRENT_FUNCTION}: Adding directory "
            "${ARGS_SUBDIR} to project ${PROJECT_NAME}")
    add_subdirectory("${ARGS_SUBDIR}")
    set(subdirs_added TRUE)
  endif()
endmacro()

#
# Adds subdirectories following JGD's project layout conventions, which are the
# canonical project layout conventions. Component, single library, and
# COMPONENTS argument. That is, the relative directories
# ./<project>-<component>/<project>/<component> or just ./<project> and possibly
# ./lib<project> are added as a subdirectories, depending upon if the project
# has components or not. These paths are relative to the location of the calling
# CMake script.
#
# This function is not meant as a complete replacement for add_subdirectory(),
# but instead makes adding the project's default directories, following the
# layout conventions, easier.
#
# Arguments:
#
# COMPONENTS: multi value arg; list of components that the PROJECT encapsulates.
# Optional and shouldn't be used if the project doesn't contain any components.
# Components that match the PROJECT_NAME will be ignored.
#
function(jgd_add_default_source_subdirectories)
  jgd_parse_arguments(MULTI_VALUE_KEYWORDS "COMPONENTS" ARGUMENTS "${ARGN}")
  jgd_validate_arguments()

  set(subdirs_added FALSE)
  list(REMOVE_ITEM ARGS_COMPONENTS "${PROJECT_NAME}")

  if(DEFINED ARGS_COMPONENTS)
    # add all components' subdirectories
    foreach(component ${ARGS_COMPONENTS})
      set(subdirs_added FALSE)
      jgd_canonical_component_subdir(COMPONENT "${component}" OUT_VAR
                                     subdir_path)
      _add_subdir_check(SUBDIR "${subdir_path}")
      if(NOT subdirs_added)
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
    _add_subdir_check(SUBDIR "${lib_subdir}")
  endif()

  # add executable source subdirectory, if it exists
  jgd_canonical_exec_subdir(OUT_VAR exec_subdir)
  _add_subdir_check(SUBDIR "${exec_subdir}")

  if(NOT subdirs_added)
    message(
      FATAL_ERROR
        "${CMAKE_CURRENT_FUNCTION} could not add any subdirectories for "
        "project ${PROJECT_NAME}. No COMPONENTS were provided, and neither the "
        "library subdirectory, ${lib_subdir}, nor the executable subdirectory, "
        "${exec_subdir}, exist.")
  endif()
endfunction()

# if always check for exec
