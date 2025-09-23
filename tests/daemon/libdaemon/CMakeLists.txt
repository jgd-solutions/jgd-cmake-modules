jcm_add_library(
  OUT_TARGET lib-target
  PUBLIC_CXX_MODULES
    protocol.mpp
  SOURCES
    protocol.cpp)

target_compile_features(${lib-target} PUBLIC cxx_std_20)