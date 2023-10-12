include(JcmTargetSources)

jcm_add_target_sources(
  TARGET libsingle::libsingle
  PUBLIC_HEADERS steal.hpp
  SOURCES steal.cpp)