include(JgdAddDefaultDoxygenDocs)
include(JgdGetDefaultLibraryTargetName)

jgd_get_default_library_target_name(OUT_VAR lib_name)
message(STATUS "HEEEEEEEEEEEEEER lib name: ${lib_name}")
jgd_add_default_doxygen_docs(TARGETS "${lib_name}")
