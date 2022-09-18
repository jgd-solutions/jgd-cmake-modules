jcm_configure_file(IN_FILE single-exec_config.hpp.in)

jcm_add_executable(
  OUT_TARGET_NAME exec-target
  SOURCES main.cpp
  LIB_SOURCES exec.hpp exec.cpp
)

jcm_add_test_executable(
  NAME ${PROJECT_NAME}-unit-test
  SOURCES exec.test.cpp
  LIBS ${exec-target}-library
)
