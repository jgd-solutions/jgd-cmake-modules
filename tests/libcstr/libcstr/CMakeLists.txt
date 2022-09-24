# Create a library to ensure sample code compiles
include(JcmAddLibrary)
jcm_add_library(
    PUBLIC_HEADERS cstr.h
    SOURCES cstr.c)

jcm_add_test_executable(
    NAME libcstr_ut
    LIBS libcstr::libcstr
    SOURCES cstr.test.c
)
