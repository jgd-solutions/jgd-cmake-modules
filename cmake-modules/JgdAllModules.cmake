file(GLOB cmake_modules "*.cmake")
list(REMOVE_ITEM cmake_modules ${CMAKE_CURRENT_LIST_FILE})

foreach(module "${cmake_modules}")
  include(${module})
endforeach()
