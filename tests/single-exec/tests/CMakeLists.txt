# Run the main executable to test its operation
add_test(NAME ${PROJECT_NAME} COMMAND ${PROJECT_NAME})

include(JgdAddTestExecutable)
jgd_add_test_executable(EXECUTABLE single-exec-test)