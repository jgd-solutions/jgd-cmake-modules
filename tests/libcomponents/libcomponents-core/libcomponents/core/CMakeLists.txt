include(JgdAddLibrary)
jgd_add_library(COMPONENT "${JGD_CURRENT_COMPONENT}"
  PUBLIC_HEADERS reader.hpp
  PRIVATE_HEADERS "${JGD_HEADER_DESTINATION}/libcomponents_config.hpp"
  SOURCES reader.cpp)
