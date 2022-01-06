include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdAddDefaultSourceSubdirectories)
include(JgdExpandDirectories)
include(JgdCanonicalStructure)
include(JgdDefaultTargetProps)

function(jgd_add_default_doxygen_docs)
  jgd_parse_arguments(MULTI_VALUE_KEYWORDS "TARGETS" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "TARGETS")

  # Extract all include directories from targets
  set(include_dirs)
  foreach(target ${ARGS_TARGETS})
    message(STATUS "currnet target: ${target}")
    get_target_property(target_dirs ${target} INTERFACE_INCLUDE_DIRECTORIES)
    message(STATUS "currnet target prop: ${target_dirs}")
    string(REGEX REPLACE "\\$<BUILD_INTERFACE:|>" "" target_dirs
                         "${target_dirs}")
    message(STATUS "current dirs twithout genex: ${target_dirs}")
    foreach(dir ${target_dirs})
      message(STATUS "current input path: ${dir}")
      file(REAL_PATH "${dir}" full_dir)
      message(STATUS "current abs input path: ${full_dir}")
      list(APPEND include_dirs "${full_dir}")
    endforeach()
  endforeach()

  list(REMOVE_DUPLICATES include_dirs)

  message(STATUS "include dirs: ${include_dirs}")

  if(include_dirs)
    # Expand each include directory into files
    message(STATUS "paths to expand: ${include_dirs}")
    jgd_expand_directories(PATHS "${include_dirs}" GLOB
                           "*${JGD_HEADER_EXTENSION}" OUT_FILES header_files)

    # Target to generate Doxygen documentation
    set(DOXYGEN_STRIP_FROM_INC_PATH "${include_dirs}")
    set(DOXYGEN_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/doxygen")
    doxygen_add_docs(doxygen-docs "${include_dirs}" ALL
                     WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")
  endif()
endfunction()
