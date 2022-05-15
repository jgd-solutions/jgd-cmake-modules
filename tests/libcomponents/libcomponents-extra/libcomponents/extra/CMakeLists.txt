include(JgdAddLibrary)
jgd_add_library(
  COMPONENT "${JGD_CURRENT_COMPONENT}"
  PUBLIC_HEADERS extra.hpp more.hpp
  SOURCES extra.cpp more.cpp)
