include(JgdDoxygenDocs)
include(JgdGetDefaultLibraryTargetName)

jgd_get_default_library_target_name(OUT_VAR lib_name)
message(STATUS "HEEEEEEEEEEEEEER lib name: ${lib_name}")
jgd_create_doxygen_target(TARGETS "${lib_name}" EXCLUDE_REGEX
                          "libsingle_config.hpp$")
