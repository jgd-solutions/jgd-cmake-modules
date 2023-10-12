include(JcmAddTestExecutable)

# Run the executables to test its operation
add_test(NAME run_compiler COMMAND many-exec::compiler arg COMMAND_EXPAND_LISTS)
add_test(NAME run_formatter COMMAND many-exec::formatter arg COMMAND_EXPAND_LISTS)

# Run separate pretend "integration" test
jcm_add_test_executable(
  NAME ${PROJECT_NAME}-integration
  SOURCES integration.cpp
  LIBS
    many-exec::compiler-library
    many-exec::formatter-library)
