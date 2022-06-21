include(JcmAddLibrary)

jcm_add_library(
  OUT_TARGET_NAME target
  COMPONENT "${JCM_CURRENT_COMPONENT}"
  PUBLIC_HEADERS extra.hpp more.hpp
  SOURCES extra.cpp more.cpp)

target_link_libraries(${target}
  INTERFACE libcomponents::core
)

# part of testing:
if(LIBCOMPONENTS_OMIT_TARGETS)
  message(FATAL_ERROR
    "LIBCOMPONENTS_OMIT_TARGETS set, yet 'extra' component's subdirectory still added")
endif()
