jcm_configure_file(
  IN_FILE libsingle_config.hpp.in
  OUT_FILE_VAR configured_header)

jcm_add_library(
  PUBLIC_HEADERS widget.hpp factory.hpp
  PRIVATE_HEADERS steal.hpp "${configured_header}"
  SOURCES widget.cpp factory.cpp)

jcm_add_test_executable(
  NAME widget-unit-test
  SOURCES widget.test.cpp
  LIBS libsingle::libsingle)
