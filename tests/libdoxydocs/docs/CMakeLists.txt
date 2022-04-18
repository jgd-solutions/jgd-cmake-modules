include(JgdDoxygenDocs)
include(JgdTargetNaming)

jgd_library_naming(OUT_TARGET_NAME lib_name)
jgd_create_doxygen_target(TARGETS "${lib_name}" README_MAIN_PAGE EXCLUDE_REGEX
  "libdoxydocs_config.hpp$|export_macros.hpp$")
