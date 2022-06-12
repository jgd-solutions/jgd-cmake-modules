# Create basic test to ensure validity of sample code with documentation
include(JcmAddTestExecutable)
jcm_add_test_executable(EXECUTABLE ${PROJECT_NAME}-test LIBS
  libsingle::libsingle SOURCES test.cpp)
