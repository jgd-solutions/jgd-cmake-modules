include(JgdParseArguments)
include(JgdValidateArguments)

# Adds subdirectories following JGD's C++ project layout conventions, based on
# the PROJECT and COMPONENTS arguments. That is, the relative directories
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
# PROJECT: one value arg; the name of the project. Optional - if not provided
# PROJECT_NAME will be used.
#
# COMPONENTS: multi value arg; list of components that the PROJECT encapsulates.
# Optional and shouldn't be used if the project doesn't contain any components.
#
function(jgd_add_default_source_subdirectories)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "PROJECT" MULTI_VALUE_KEYWORDS
                      "COMPONENTS" ARGUMENTS "${ARGN}")
  jgd_validate_arguments()

  set(project "${PROJECT_NAME}")
  if(ARGS_PROJECT)
    set(project "${ARGS_PROJECT}")
  endif()

  # Add Source File Subdirectories
  if(DEFINED ARGS_COMPONENTS)
    # add all components' subdirectories
    foreach(component "${ARGS_COMPONENTS}")
      string(JOIN "-" comp_dir ${project} ${component})
      set(subdir_path
          "${${project}_SOURCE_DIR}/${comp_dir}/${project}/${component}")
      if(IS_DIRECTORY "${subdir_path}")
        message(DEBUG "${CMAKE_CURRENT_FUNCTION}: Adding directory "
                "${subdir_path} to project ${project}")
        add_subdirectory(${subdir_path})
      else()
        message(
          FATAL_ERROR
            "In ${CMAKE_CURRENT_FUNCTION}. Cannot add subdirectory "
            "${subdir_path} for component ${component} of project "
            "${project}. Directory does not exist.")
      endif()
    endforeach()
  else()
    # add single project source subdirectory
    set(subdir_path "${${project}_SOURCE_DIR}/${project}")
    if(IS_DIRECTORY "${subdir_path}")
      message(DEBUG "${CMAKE_CURRENT_FUNCTION}: Adding directory "
              "${subdir_path} to project ${project}")
      add_subdirectory(${subdir_path})
    else()
      message(
        FATAL_ERROR
          "In ${CMAKE_CURRENT_FUNCTION}. Cannot add subdirectory "
          "${subdir_path} for project ${project}. Directory does " "not exist.")
    endif()

    # add additional library source subdirectory, if project is executable
    string(REGEX REPLACE "^lib" "" no_lib "${project}")
    if("${no_lib}" STREQUAL "${project}")
      set(subdir_path "${${project}_SOURCE_DIR}/lib${project}")
      if(IS_DIRECTORY "${subdir_path}")
        message(DEBUG "${CMAKE_CURRENT_FUNCTION}: Adding directory "
                "${subdir_path} to project ${project}")
        add_subdirectory(${subdir_path})
      endif()
    endif()

  endif()

endfunction()
