include(JcmAddLibrary)

jcm_add_library(COMPONENT "${JCM_CURRENT_COMPONENT}"
  OUT_TARGET target
  PUBLIC_HEADERS reader.hpp
  PRIVATE_HEADERS "${PROJECT_BINARY_DIR}/libcomponents/libcomponents_config.hpp"
  SOURCES reader.cpp
)

target_compile_features(${target} PRIVATE cxx_std_17)
