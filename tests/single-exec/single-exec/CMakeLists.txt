include(JgdAddExecutable)
include(JgdAddTestExecutable)

jgd_add_executable(EXECUTABLE ${PROJECT_NAME} MAIN_SOURCES main.cpp SOURCES exec.hpp exec.cpp)
jgd_add_test_executable(EXECUTABLE exec-unit-test SOURCES exec.test.cpp LIBS ${PROJECT_NAME}-object-lib)