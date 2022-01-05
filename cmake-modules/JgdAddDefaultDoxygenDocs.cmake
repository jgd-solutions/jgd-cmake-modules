include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdExpandDirectories)
include(JgdCanonicalStructure)
include(JgdAddDefaultSourceSubdirectories)

# headers provided
function(jgd_add_default_doxygen_docs)
  jgd_parse_arguments(MULTI_VALUE_KEYWORDS "HEADERS;COMPONENTS" ARGUMENTS
                      "${ARGN}")
  jgd_validate_arguments()

  # expand the header paths

  jgd_expand_directories(PATHS ${ARGS_HEADERS} OUT_FILES header_files GLOB
                         "*${JGD_HEADER_EXTENSION}")

  # Find all the public headers
  jgd_canonical_lib_subdir(OUT_VAR source_dir)
  file(GLOB_RECURSE public_headers "${source_dir}/*${JGD_HEADER_EXTENSION}")

  jgd_default_include_dirs(SOURCE_DIR "${source_dir}" OUT_VAR include_dirs)
  list(GET include_dirs 0 source_include_dir)

  # Add 'docs' target to make Doxygen docs
  set(DOXYGEN_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/doxygen")
  set(DOXYGEN_STRIP_FROM_INC_PATH "${source_include_dir}")
  doxygen_add_docs(docs ${public_headers} ALL
                   WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")
endfunction()
