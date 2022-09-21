include(JcmAddLibrary)

jcm_configure_file(IN_FILE extra_config.hpp.in)

jcm_add_library(
  OUT_TARGET target
  COMPONENT "${JCM_CURRENT_COMPONENT}"
  PUBLIC_HEADERS extra.hpp more.hpp
  SOURCES extra.cpp more.cpp)

target_link_libraries(${target}
  INTERFACE libcomponents::core
)

# part of testing:
if(LIBCOMPONENTS_OMIT_TARGETS MATCHES "libcomponents::extra")
  message(FATAL_ERROR
    "LIBCOMPONENTS_OMIT_TARGETS contains 'extra', yet 'extra' component's subdirectory still added")
endif()
