jcm_add_executable(
  COMPONENT formatter
  OUT_TARGET formatter-target
  SOURCES main.cpp
  LIB_SOURCES reformat.hpp ../shared.hpp empty.cpp)

add_subdirectory(formats) # organize files into dirs to test jcm_add_target_sources
target_compile_features(${formatter-target} PUBLIC cxx_std_20)

get_target_property(features ${formatter-target} COMPILE_FEATURES)
get_target_property(interface-features ${formatter-target} COMPILE_FEATURES)

message(WARNING "features: ${features}")
message(WARNING "interface features: ${interface-features}")

jcm_add_test_executable(
  NAME ${PROJECT_NAME}-formatter_ut
  SOURCES reformat.test.cpp
  LIBS ${formatter-target}-library)
