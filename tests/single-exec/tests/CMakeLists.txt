include(JcmTargetNaming)
include(JcmAddTestExecutable)

# Run the main executable to test its operation
jcm_executable_naming(OUT_TARGET exec-target)
add_test(NAME ${exec-target} COMMAND ${exec-target})

# Run separate "integration" test, testing associated library from main exec
jcm_add_test_executable(
  NAME ${PROJECT_NAME}-integration
  SOURCES integration.cpp
  LIBS ${exec-target}-library)
