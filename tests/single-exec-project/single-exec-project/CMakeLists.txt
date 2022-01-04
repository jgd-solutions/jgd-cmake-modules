include(JgdAddDefaultExecutable)

jgd_add_default_executable(EXECUTABLE ${PROJECT_NAME} SOURCES main.cpp test.hpp
                           test.cpp)

include(CMakePrintHelpers)
cmake_print_properties(
  TARGETS ${PROJECT_NAME} PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
                                     INCLUDE_DIRECTORIES)
