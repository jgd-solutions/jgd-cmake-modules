jcm_add_executable(
  OUT_TARGET compiler-target
  COMPONENT compiler
  SOURCES main.cpp "${many-exec_config_file}"
  LIB_SOURCES compile.hpp ../shared.hpp)

target_compile_features(${compiler-target} PUBLIC cxx_std_20)

jcm_add_test_executable(
  NAME ${PROJECT_NAME}-compiler_ut
  SOURCES compile.test.cpp
  LIBS ${compiler-target}-library)
