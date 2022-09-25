include(JcmCreateAccessoryTargets)

jcm_create_doxygen_target(
  README_MAIN_PAGE
  SOURCE_TARGETS libsingle::libsingle
  EXCLUDE_REGEX "export_macros.hpp$"
)
