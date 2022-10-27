include(JcmAddLibrary)

jcm_configure_file(IN_FILE extra_config.hpp.in OUT_FILE_VAR extra_config_file)

jcm_add_library(
  OUT_TARGET target
  COMPONENT "${JCM_CURRENT_COMPONENT}"
  PUBLIC_HEADERS extra.hpp more.hpp
  PRIVATE_HEADERS "${extra_config_file}"
  SOURCES extra.cpp more.cpp)

target_link_libraries(${target} INTERFACE libcomponents::core)

# part of testing JCM:
if(NOT LIBCOMPONENTS_BUILD_EXTRA)
  message(FATAL_ERROR  "'LIBCOMPONENTS_BUILD_EXTRA' is OFF, yet 'extra' component's subdirectory still added")
endif()
