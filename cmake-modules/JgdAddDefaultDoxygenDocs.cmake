include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdAddDefaultSourceSubdirectories)
include(JgdExpandDirectories)
include(JgdCanonicalStructure)
include(JgdDefaultTargetProps)

function(jgd_add_default_doxygen_docs)
  jgd_parse_arguments(ARGUMENTS "${ARGN}")
  jgd_validate_arguments()

  set(DOXYGEN_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/doxygen")
  set(DOXYGEN_STRIP_FROM_INC_PATH)

  set(components ${JGD_PROJECT_COMPONENTS})
  list(REMOVE_ITEM components ${PROJECT_NAME})

  # get source subdirectories -> component directories will be first
  jgd_add_default_source_subdirectories(
    NO_ADD_SUBDIRECTORY OUT_VAR source_subdirs COMPONENTS ${components})

  # get include dirs of the first component dirs
  list(LENGTH components num_components)

  foreach(i RANGE 1 ${num_components})
    jgd_default_include_dirs(COMPONENT ${component} SOURCE_DIR "${source_subdir}")
  endforeach()
  # get include dirs of the remaining dirs, which will be lib or exec for proj



function(jgd_default_include_dirs)
  jgd_parse_arguments(OPTIONS "BUILD_INTERFACE" ONE_VALUE_KEYWORDS
                      "COMPONENT;OUT_VAR;SOURCE_DIR" ARGUMENTS "${ARGN}")
    jgd_parse_arguments(OPTIONS "BUILD_INTERFACE" ONE_VALUE_KEYWORDS
                        "COMPONENT;OUT_VAR;SOURCE_DIR" ARGUMENTS "${ARGN}")
  endforeach()

  list(APPEND DOXYGEN_STRIP_FROM_INC_PATH "${include_dir}")
  jgd_expand_directories(PATHS "${source_subdirs}" OUT_FILES headers GLOB
                         "*${JGD_HEADER_EXTENSION}")

  set(header_files)
  foreach(include_dir ${source_subdirs})
    message(STATUS "before: ${include_dir} current dir: ${include_dir}")
    if(dir_headers)
      list(APPEND header_files "${dir_headers}")
    endif()
  endforeach()

  doxygen_add_docs(doxygen-docs "${header_files}" ALL
                   WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")
endfunction()


  # Move the main project component to the end of the components list.  It has
  # the shortest include path, so this prevents its path from matching library
  # components' include paths when Doxygen is stripping include paths. This only
  # applies when there are library components and a main project component to a
  # project.
  set(components ${JGD_PROJECT_COMPONENTS})
  list(FIND components "${PROJECT_NAME}" proj_comp_idx)
  if(NOT ${proj_comp_idx} EQUAL -1)
    list(REMOVE_AT components ${proj_comp_idx})
    list(APPEND components ${PROJECT_NAME})
  endif()
