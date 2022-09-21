include(JcmAddLibrary)

jcm_add_library(COMPONENT "${JCM_CURRENT_COMPONENT}"
  OUT_TARGET target
  PUBLIC_HEADERS reader.hpp
  SOURCES reader.cpp
)

target_link_libraries(${target} PRIVATE libcomponents_mutual)
