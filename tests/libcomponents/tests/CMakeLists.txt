if(NOT LIBCOMPONENTS_ENABLE_EXTRA)
  return()
endif()

include(JcmAddExecutable)

jcm_add_test_executable(
  NAME components-test
  LIBS
    libcomponents::core
    libcomponents::extra
  SOURCES test.cpp)
