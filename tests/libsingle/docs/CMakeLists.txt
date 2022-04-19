include(JgdDoxygenDocs)
jgd_create_doxygen_target(TARGETS libdoxydocs::libdoxydocs README_MAIN_PAGE EXCLUDE_REGEX
  "libdoxydocs_config.hpp$|export_macros.hpp$")
