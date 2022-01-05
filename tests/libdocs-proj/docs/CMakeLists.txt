include(JgdCanonicalStructure)
include(JgdDefaultTargetProps)

# Find all the public headers
jgd_canonical_lib_subdir(OUT_VAR source_dir)
file(GLOB_RECURSE public_headers "${source_dir}/*${JGD_HEADER_EXTENSION}")

jgd_default_include_dirs(SOURCE_DIR "${source_dir}" OUT_VAR include_dirs)
list(GET include_dirs 0 source_include_dir)

set(DOXYGEN_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/doxygen")
set(DOXYGEN_STRIP_FROM_INC_PATH "${source_include_dir}")
doxygen_add_docs(docs ${public_headers} ALL
                 WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")
