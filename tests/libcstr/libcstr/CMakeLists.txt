# Create a library to ensure sample code compiles
include(JcmAddLibrary)
jcm_add_library(
    OUT_TARGET target
    PUBLIC_HEADERS cstr.h
    SOURCES cstr.c)

get_target_property(compile_options ${target} COMPILE_OPTIONS)
if(NOT compile_options)
  message(FATAL_ERROR "Failed to apply default COMPILE_OPTIONS to target ${target}")
endif()

jcm_add_test_executable(
    NAME libcstr_ut
    LIBS libcstr::libcstr
    SOURCES cstr.test.c)
