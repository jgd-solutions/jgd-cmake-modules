include(JcmAddTestExecutable)
jcm_add_test_executable(
  NAME components-test
  LIBS
    libcomponents::core
    libcomponents::extra
  SOURCES test.cpp
)
