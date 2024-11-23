jcm_add_library(
  OUT_TARGET lib-target
  PUBLIC_HEADERS
    protocol.hpp
  SOURCES
    protocol.cpp)

target_compile_features(${lib-target} PUBLIC cxx_std_17)