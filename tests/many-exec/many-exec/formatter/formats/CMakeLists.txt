# this directory is entirely to test the operation of jcm_add_target_sources against an executable
# component with various file types
include(JcmTargetSources)

jcm_add_target_sources(
  TARGET many-exec::formatter-library
  PUBLIC_HEADERS upper_format.hpp
  PRIVATE_HEADERS internal_to_upper.hpp
  SOURCES internal_to_upper.cpp upper_format.cpp)