configure_file("${CMAKE_CURRENT_SOURCE_DIR}/conf.py.in" "conf.py")

function(jcm_create_sphinx_target)
  set(sphinx_config_dir "${CMAKE_CURRENT_BINARY_DIR}")
  set(sphinx_source_dir "${CMAKE_CURRENT_LIST_DIR}")
  set(sphinx_build_dir "${CMAKE_CURRENT_BINARY_DIR}/sphinx")

  add_custom_target(sphinx-docs
    COMMAND
      Sphinx::build
      -c "${sphinx_config_dir}"
      "${sphinx_source_dir}"
      "${sphinx_build_dir}"
  )
endfunction()

jcm_create_sphinx_target()
