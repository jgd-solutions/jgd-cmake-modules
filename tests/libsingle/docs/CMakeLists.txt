include(JcmCreateAccessoryTargets)
jcm_create_doxygen_target(
  TARGETS libsingle::libsingle
  README_MAIN_PAGE EXCLUDE_REGEX
  "libsingle_config.hpp$|export_macros.hpp$"
)
