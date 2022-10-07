include(JcmAddLibrary)

jcm_add_library(COMPONENT "${JCM_CURRENT_COMPONENT}"
  OUT_TARGET core-target
  PUBLIC_HEADERS reader.hpp
  PRIVATE_HEADERS "${PROJECT_BINARY_DIR}/libcomponents/libcomponents_config.hpp"
  SOURCES reader.cpp
)

add_subdirectory(private)

target_compile_features(${core-target} PRIVATE cxx_std_17)
