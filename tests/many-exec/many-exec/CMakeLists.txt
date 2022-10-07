jcm_configure_file(IN_FILE many-exec_config.hpp.in)

# again, example of omitting targets from configuration process
set(exec_components)

if(MANY_EXEC_BUILD_COMPILER)
  list(APPEND exec_components compiler)
endif()

if(MANY_EXEC_BUILD_FORMATTER)
  list(APPEND exec_components formatter)
endif()

jcm_source_subdirectories(ADD_SUBDIRS EXEC_COMPONENTS ${exec_components})
