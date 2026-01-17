jcm_add_target_sources(
  TARGET ${core-target}
  PRIVATE_HEADERS "private.hpp")

target_sources(${core-target} PRIVATE private.hpp private.cpp)
