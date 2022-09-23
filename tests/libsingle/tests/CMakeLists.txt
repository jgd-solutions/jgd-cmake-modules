# Create basic test to ensure validity of sample code with documentation
include(JcmAddTestExecutable)
jcm_add_test_executable(
  NAME ${PROJECT_NAME}-test
  SOURCES test.cpp
  LIBS libsingle::libsingle
)
