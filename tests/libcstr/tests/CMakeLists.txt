# Create basic test to ensure validity of sample code
include(JcmAddExecutable)
jcm_add_test_executable(
  NAME ${PROJECT_NAME}-test
  SOURCES test.c
  LIBS libcstr::libcstr
)
