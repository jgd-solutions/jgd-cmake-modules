# Create basic test to ensure validity of sample code with documentation
include(JgdAddTestExecutable)
jgd_add_test_executable(EXECUTABLE ${PROJECT_NAME}-test
  LIBS libdoxydocs::libdoxydocs SOURCES test.cpp)