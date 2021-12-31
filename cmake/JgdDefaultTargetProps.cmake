# cmake-lint: disable=C0301
set(JGD_DEFAULT_COMPILE_OPTIONS
    $<$<OR:$<CXX_COMPILER_ID:Clang>,$<CXX_COMPILER_ID:AppleClang>,$<CXX_COMPILER_ID:GNU>>:
    -Wall
    -Wextra
    -Wpedantic
    -Wconversion
    -Wsign-conversion>
    $<$<CXX_COMPILER_ID:MSVC>:
    /W4>)

set(JGD_DEFAULT_INCLUDE_DIRS $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}>
                             $<INSTALL_INTERFACE:include>)

set(JGD_DEFAULT_TEST_LIB "boost::ut")
