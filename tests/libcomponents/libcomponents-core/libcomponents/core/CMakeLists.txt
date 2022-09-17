include(JcmAddLibrary)

jcm_add_library(COMPONENT "${JCM_CURRENT_COMPONENT}"
  PUBLIC_HEADERS reader.hpp
  PRIVATE_HEADERS "${PROJECT_BINARY_DIR}/libcomponents/libcomponents_config.hpp"
  SOURCES reader.cpp
)
