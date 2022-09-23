include(JcmAddTestExecutable)

# Run the executables to test its operation
add_test(NAME run_compiler COMMAND many-exec::compiler arg)
add_test(NAME run_formatter COMMAND many-exec::formatter arg)

# Run separate pretend "integration" test
jcm_add_test_executable(
  NAME ${PROJECT_NAME}-integration
  SOURCES integration.cpp
  LIBS
    many-exec_many-exec-compiler-library
    many-exec_many-exec-formatter-library
)
