# Create a library to ensure sample code compiles
include(JgdAddLibrary)
jgd_add_library(PUBLIC_HEADERS widget.hpp factory.hpp SOURCES widget.cpp factory.cpp)
