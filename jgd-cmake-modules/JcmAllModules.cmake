include_guard()

#[=======================================================================[.rst:

JcmAllModules
-------------

When included, includes all of JCM's CMake modules, excluding any `Find Modules
<https://cmake.org/cmake/help/latest/manual/cmake-developer.7.html#find-modules>.

#]=======================================================================]

file(
  GLOB jcm_cmake_modules_to_include
  LIST_DIRECTORIES false
  "${CMAKE_CURRENT_LIST_DIR}/*.cmake"
)

list(
  REMOVE_ITEM
  jcm_cmake_modules_to_include
  "${CMAKE_CURRENT_LIST_FILE}"
)

list(FILTER jcm_cmake_modules_to_include EXCLUDE REGEX "Find.+\.cmake$")

foreach(module IN LISTS jcm_cmake_modules_to_include)
  include(${module})
endforeach()

unset(jcm_cmake_modules_to_include)
