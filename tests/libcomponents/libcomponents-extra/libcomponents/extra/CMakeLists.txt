include(JgdAddLibrary)

jgd_add_library(
  OUT_TARGET_NAME target
  COMPONENT "${JGD_CURRENT_COMPONENT}"
  PUBLIC_HEADERS extra.hpp more.hpp
  SOURCES extra.cpp more.cpp)

target_link_libraries(${target} INTERFACE libcomponents::core)
