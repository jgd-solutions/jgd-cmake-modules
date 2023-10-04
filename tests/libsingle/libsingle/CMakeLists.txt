jcm_configure_file(
  IN_FILE libsingle_config.hpp.in
  OUT_FILE_VAR configured_header)

jcm_add_library(
  OUT_TARGET target
  PUBLIC_HEADERS widget.hpp factory.hpp
  PRIVATE_HEADERS "${configured_header}"
  SOURCES widget.cpp factory.cpp)

# simply a subdirectory that's complex enough to warrant a
# separate CMakeLists.txt file. Subdirectory tests jcm_add_target_sources
add_subdirectory(material)

target_compile_features(${target} PRIVATE cxx_std_17)

jcm_add_test_executable(
  NAME widget-unit-test
  SOURCES widget.test.cpp
  LIBS libsingle::libsingle)
