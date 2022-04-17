# Run the main executable to test its operation
add_test(NAME ${PROJECT_NAME} COMMAND ${PROJECT_NAME})

# Run separate "integration" test, testing object library from main exec
include(JgdAddTestExecutable)
jgd_add_test_executable(EXECUTABLE ${PROJECT_NAME}-integration SOURCES integration.cpp LIBS ${PROJECT_NAME}-object-lib)

