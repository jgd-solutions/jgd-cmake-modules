jgd_add_library(TYPE INTERFACE INTERFACE_HEADERS equality.hpp sum.hpp)
target_compile_features(libheaders_libheaders INTERFACE cxx_std_20)

jgd_add_test_executable(EXECUTABLE equality-ut SOURCES equality.test.cpp LIBS libheaders::libheaders)
jgd_add_test_executable(EXECUTABLE sum-ut SOURCES sum.test.cpp LIBS libheaders::libheaders)
