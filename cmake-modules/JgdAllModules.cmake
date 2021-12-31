file(GLOB cmake_modules "*.cmake")
list(REMOVE_ITEM cmake_modules JgdAllModules.cmake)

foreach(module ${cmake_modules})
  include(${module})
endforeach()
