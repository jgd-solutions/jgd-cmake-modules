include_guard()

#[=======================================================================[.rst:

JcmDefaultCompileOptions
-------------------------

:github:`JcmDefaultCompileOptions`

Defines variables with default compile options for common compilers. These are used to initialize
the `COMPILE_OPTIONS` properties when library or executable targets are created with JCM functions.
Of course, like any of the defaults introduced by JCM, these can easily be overridden on the target
after it's created.

.. note::
  Only `CXX_COMPILER_ID` and `C_COMPILER_ID` are currently considered. This is
  to be extended to other languages

The following variables are defined:

:cmake:variable:`JCM_DEFAULT_CXX_COMPILE_OPTIONS_GNU`
  -Wall
  -Wextra
  -Wpedantic
  -Wconversion
  -Wsign-conversion
  -Weffc++
  -Wno-non-virtual-dtor
  -Wdelete-non-virtual-dtor

:cmake:variable:`JCM_DEFAULT_C_COMPILE_OPTIONS_GNU`
  -Wall
  -Wextra
  -Wpedantic
  -Wconversion
  -Wsign-conversion

:cmake:variable:`JCM_DEFAULT_CXX_COMPILE_OPTIONS_CLANG`
  Same as :cmake:variable:`JCM_DEFAULT_CXX_COMPILE_OPTIONS_GNU`

:cmake:variable:`JCM_DEFAULT_C_COMPILE_OPTIONS_CLANG`
  Same as :cmake:variable:`JCM_DEFAULT_C_COMPILE_OPTIONS_GNU`

:cmake:variable:`JCM_DEFAULT_CXX_COMPILE_OPTIONS_MSVC`
  /W4
  /WX

:cmake:variable:`JCM_DEFAULT_C_COMPILE_OPTIONS_MSVC`
  Same as :cmake:variable:`JCM_DEFAULT_CXX_COMPILE_OPTIONS_MSVC`

:cmake:variable:`JCM_DEFAULT_COMPILE_OPTIONS`
  A generator expression that will resolve to the appropriate set of the variables above based on
  the compiler and language. This is used to initialize targets' `COMPILE_OPTIONS`.

--------------------------------------------------------------------------

#]=======================================================================]

list(
  APPEND
  JCM_DEFAULT_CXX_COMPILE_OPTIONS_GNU
  -Wall
  -Wextra
  -Wpedantic
  -Wconversion
  -Wsign-conversion
  -Weffc++
  -Wno-non-virtual-dtor)

list(
  APPEND
  JCM_DEFAULT_C_COMPILE_OPTIONS_GNU
  -Wall
  -Wextra
  -Wpedantic
  -Wconversion
  -Wsign-conversion)

set(JCM_DEFAULT_CXX_COMPILE_OPTIONS_CLANG ${JCM_DEFAULT_CXX_COMPILE_OPTIONS_GNU})
set(JCM_DEFAULT_C_COMPILE_OPTIONS_CLANG ${JCM_DEFAULT_C_COMPILE_OPTIONS_GNU})

set(JCM_DEFAULT_CXX_COMPILE_OPTIONS_MSVC /W4 /WX)
set(JCM_DEFAULT_C_COMPILE_OPTIONS_MSVC /W4 /WX)

string(CONCAT JCM_DEFAULT_COMPILE_OPTIONS
  "$<REMOVE_DUPLICATES:"
    "$<$<COMPILE_LANGUAGE:CXX>:" # compiling cxx
      "$<$<CXX_COMPILER_ID:GNU>:${JCM_DEFAULT_CXX_COMPILE_OPTIONS_GNU}>"
      "$<$<CXX_COMPILER_ID:Clang,AppleClang>:${JCM_DEFAULT_CXX_COMPILE_OPTIONS_CLANG}>"
      "$<$<CXX_COMPILER_ID:MSVC>:${JCM_DEFAULT_CXX_COMPILE_OPTIONS_MSVC}>"
    ">;"
    "$<$<COMPILE_LANGUAGE:C>:" # compiling c
      "$<$<C_COMPILER_ID:GNU>:${JCM_DEFAULT_C_COMPILE_OPTIONS_GNU}>"
      "$<$<C_COMPILER_ID:Clang,AppleClang>:${JCM_DEFAULT_C_COMPILE_OPTIONS_CLANG}>"
      "$<$<C_COMPILER_ID:MSVC>:${JCM_DEFAULT_C_COMPILE_OPTIONS_MSVC}>"
    ">"
  ">")
