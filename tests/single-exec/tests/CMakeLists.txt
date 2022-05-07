include(JgdTargetNaming)
include(JgdAddTestExecutable)

# Run the main executable to test its operation
jgd_executable_naming(OUT_TARGET_NAME exec-target)
add_test(NAME ${exec-target} COMMAND ${exec-target})

# Run separate "integration" test, testing object library from main exec
jgd_add_test_executable(
  EXECUTABLE ${PROJECT_NAME}-integration
  SOURCES integration.cpp
  LIBS ${exec-target}-objects)
