# Create basic test to ensure validity of sample code with documentation

include(JgdAddDefaultTestExecutable)
jgd_add_default_test_executable(EXECUTABLE docs-tests LIBS
                                libdocs-proj::libdocs-proj SOURCES test.cpp)
