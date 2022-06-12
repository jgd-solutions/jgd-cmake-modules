include(JcmAddExecutable)
include(JcmAddTestExecutable)

jcm_add_executable(MAIN_SOURCES main.cpp SOURCES exec.hpp exec.cpp OUT_TARGET_NAME exec-target)
jcm_add_test_executable(
  EXECUTABLE ${PROJECT_NAME}-unit-test
  SOURCES exec.test.cpp
  LIBS ${exec-target}-objects)
