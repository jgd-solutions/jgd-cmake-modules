jcm_configure_file(
    IN_FILE single_exec_config.hpp.in
    OUT_FILE_VAR config_header_file)

jcm_add_executable(
  OUT_TARGET exec-target
  SOURCES main.cpp
  LIB_SOURCES
    exec.hpp exec.cpp
    "${config_header_file}"
)

target_compile_features(${exec-target} PRIVATE cxx_std_17)

jcm_add_test_executable(
  NAME ${PROJECT_NAME}-unit-test
  SOURCES exec.test.cpp
  LIBS ${exec-target}-library
)
