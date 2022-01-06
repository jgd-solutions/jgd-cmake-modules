# Create basic test to ensure validity of sample code with documentation

include(JgdAddDefaultTestExecutable)
jgd_add_default_test_executable(EXECUTABLE libsingle-test LIBS
                                libsingle::libsingle SOURCES test.cpp)
