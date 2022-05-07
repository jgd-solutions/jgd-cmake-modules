include(JgdAddExecutable)
include(JgdAddTestExecutable)

jgd_add_executable(MAIN_SOURCES main.cpp SOURCES exec.hpp exec.cpp OUT_TARGET_NAME exec-target)
jgd_add_test_executable(
  EXECUTABLE ${PROJECT_NAME}-unit-test
  SOURCES exec.test.cpp
  LIBS ${exec-target}-objects)