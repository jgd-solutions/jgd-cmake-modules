jcm_add_executable(
  COMPONENT formatter
  OUT_TARGET formatter-target
  SOURCES main.cpp
  LIB_SOURCES ../shared.hpp reformat.hpp empty.cpp)

add_subdirectory(formats) # organize files into dirs to test jcm_add_target_sources

target_compile_features(${formatter-target} PUBLIC cxx_std_17)
target_compile_features(${formatter-target}-library PUBLIC cxx_std_20)

jcm_add_test_executable(
  NAME ${PROJECT_NAME}-formatter_ut
  SOURCES reformat.test.cpp
  LIBS ${formatter-target}-library)
