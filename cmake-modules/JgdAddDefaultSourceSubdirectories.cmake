include(JgdParseArguments)
include(JgdValidateArguments)

# Adds subdirectories following JGD's C++ project layout conventions, based on
# the PROJECT_NAME and COMPONENTS argument. That is, the relative directories
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
#
function(jgd_add_default_source_subdirectories)
  jgd_parse_arguments(MULTI_VALUE_KEYWORDS "COMPONENTS" ARGUMENTS "${ARGN}")
  jgd_validate_arguments()

  # Add Source File Subdirectories
  if(DEFINED ARGS_COMPONENTS)
    # add all components' subdirectories
    foreach(component ${ARGS_COMPONENTS})
      string(JOIN "-" comp_dir ${PROJECT_NAME} ${component})
      set(subdir_path
          "${${PROJECT_NAME}_SOURCE_DIR}/${comp_dir}/${PROJEC_NAME}/${component}"
      )
      if(IS_DIRECTORY "${subdir_path}")
        message(DEBUG "${CMAKE_CURRENT_FUNCTION}: Adding directory "
                "${subdir_path} to project ${PROJECT_NAME}")
        add_subdirectory(${subdir_path})
      else()
        message(
          FATAL_ERROR
            "In ${CMAKE_CURRENT_FUNCTION}. Cannot add subdirectory "
            "${subdir_path} for component ${component} of project "
            "${PROJECT_NAME}. Directory does not exist.")
      endif()
    endforeach()
  else()
    # add single project source subdirectory
    set(subdir_path "${${PROJECT_NAME}_SOURCE_DIR}/${PROJECT_NAME}")
    if(IS_DIRECTORY "${subdir_path}")
      message(DEBUG "${CMAKE_CURRENT_FUNCTION}: Adding directory "
              "${subdir_path} to project ${PROJECT_NAME}")
      add_subdirectory(${subdir_path})
    else()
      message(
        FATAL_ERROR
          "In ${CMAKE_CURRENT_FUNCTION}. Cannot add subdirectory "
          "${subdir_path} for project ${PROJECT_NAME}. Directory does not "
          "exist.")
    endif()

    # add additional library source subdirectory, if project is executable
    string(REGEX REPLACE "^lib" "" no_lib "${PROJECT_NAME}")
    if("${no_lib}" STREQUAL "${PROJECT_NAME}")
      set(subdir_path "${${PROJECT_NAME}_SOURCE_DIR}/lib${PROJECT_NAME}")
      if(IS_DIRECTORY "${subdir_path}")
        message(DEBUG "${CMAKE_CURRENT_FUNCTION}: Adding directory "
                "${subdir_path} to project ${PROJECT_NAME}")
        add_subdirectory(${subdir_path})
      endif()
    endif()

  endif()

endfunction()
