jcm_add_executable(
  COMPONENT compiler
  OUT_TARGET_NAME compiler-target
  SOURCES main.cpp
  LIB_SOURCES compile.hpp ../shared.hpp
)

target_compile_features(${compiler-target} PUBLIC cxx_std_20)

jcm_add_test_executable(
  NAME ${PROJECT_NAME}-compiler_ut
  SOURCES compile.test.cpp
  LIBS ${compiler-target}-library
)
