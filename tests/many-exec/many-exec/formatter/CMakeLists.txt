jcm_add_executable(
  COMPONENT formatter
  OUT_TARGET formatter-target
  SOURCES main.cpp
  LIB_SOURCES reformat.hpp ../shared.hpp
)

target_compile_features(${formatter-target} PUBLIC cxx_std_20)

jcm_add_test_executable(
  NAME ${PROJECT_NAME}-formatter_ut
  SOURCES reformat.test.cpp
  LIBS ${formatter-target}-library
)
