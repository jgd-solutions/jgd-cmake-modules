jcm_configure_file(
  IN_FILE libcomponents_config.hpp.in
  OUT_FILE_VAR configured_header)

jcm_add_library(
  NAME libcomponents_mutual
  TYPE INTERFACE
  INTERFACE_HEADERS "${configured_header}"
)

target_compile_features(libcomponents_mutual INTERFACE cxx_std_17)
