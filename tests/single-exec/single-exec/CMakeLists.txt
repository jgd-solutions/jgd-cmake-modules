include(JcmAddExecutable)
include(JcmAddTestExecutable)

jcm_add_executable(
  OUT_TARGET_NAME exec-target
  SOURCES main.cpp
  OBJ_SOURCES exec.hpp exec.cpp
)
jcm_add_test_executable(
  NAME ${PROJECT_NAME}-unit-test
  SOURCES exec.test.cpp
  LIBS ${exec-target}-objects
)
