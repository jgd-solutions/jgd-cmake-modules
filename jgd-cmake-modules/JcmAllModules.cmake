include_guard()

#[=======================================================================[.rst:

JcmAllModules
-------------

When included, includes all of JCM's CMake modules.

#]=======================================================================]

file(
  GLOB cmake_modules
  LIST_DIRECTORIES false
  "${CMAKE_CURRENT_LIST_DIR}/*.cmake")
list(REMOVE_ITEM cmake_modules "${CMAKE_CURRENT_LIST_FILE}")

foreach(module ${cmake_modules})
  include(${module})
endforeach()

unset(cmake_modules)
