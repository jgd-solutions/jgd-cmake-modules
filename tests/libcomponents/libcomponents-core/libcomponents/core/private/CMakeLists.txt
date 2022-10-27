jcm_header_file_set(PRIVATE
  TARGET ${core-target}
  HEADERS "private.hpp")

target_sources(${core-target}
  PRIVATE private.hpp private.cpp
)
