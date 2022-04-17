include_guard()

include(JgdParseArguments)
include(JgdFileNaming)
include(JgdTargetNaming)
include(JgdSeparateList)
include(JgdCanonicalStructure)
include(JgdDefaultCompileOptions)

# again, artifacts
function(jgd_add_executable)
  jgd_parse_arguments(
    ONE_VALUE_KEYWORDS
    "COMPONENT;EXECUTABLE"
    MULTI_VALUE_KEYWORDS
    "SOURCES;MAIN_SOURCES"
    REQUIRES_ALL
    "MAIN_SOURCES"
    ARGUMENTS
    "${ARGN}")

  # Set executable component
  if (DEFINED ARGS_COMPONENT AND NOT ARGS_COMPONENT STREQUAL PROJECT_NAME)
    set(comp_arg COMPONENT ${ARGS_COMPONENT})
    set(comp_err_msg "n component (${ARGS_COMPONENT})")
  endif ()

  # == Usage Guards ==

  # ensure executable is created in the appropriate canonical directory
  jgd_canonical_exec_subdir(OUT_VAR canonical_dir)
  if (NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL canonical_dir)
    message(
      FATAL_ERROR
      "Creating a${comp_err_msg} executable for project ${PROJECT_NAME} must "
      "be done in the canonical directory ${canonical_dir}.")
  endif ()

  # verify source naming
  set(regex "${JGD_HEADER_REGEX}|${JGD_SOURCE_REGEX}")
  jgd_separate_list(
    IN_LIST
    "${ARGS_SOURCES};${ARGS_MAIN_SOURCES}"
    REGEX
    "${regex}"
    TRANSFORM
    "FILENAME"
    OUT_UNMATCHED
    incorrectly_named)
  if (incorrectly_named)
    message(
      FATAL_ERROR
      "Provided source files do not match the regex for executable sources, "
      "${regex}: ${incorrectly_named}.")
  endif ()

  # == Create Executable ==

  # resolve executable names
  if (DEFINED ARGS_EXECUTABLE)
    set(target_name ${ARGS_EXECUTABLE})
    set(export_name ${ARGS_EXECUTABLE})
    set(output_name ${ARGS_EXECUTABLE})
  else ()
    jgd_executable_naming(
      ${comp_arg}
      OUT_TARGET_NAME
      target_name
      OUT_EXPORT_NAME
      export_name
      OUT_OUTPUT_NAME
      output_name)
  endif ()

  # create executable target
  add_executable(${target_name} "${ARGS_MAIN_SOURCES}")
  add_executable(${PROJECT_NAME}::${export_name} ALIAS ${target_name})

  # == Set Target Properties ==

  jgd_canonical_include_dirs(TARGET ${target_name} OUT_VAR include_dirs)

  # basic properties
  set_target_properties(${target_name}
    PROPERTIES OUTPUT_NAME ${output_name}
    EXPORT_NAME ${export_name}
    COMPILE_OPTIONS "${JGD_DEFAULT_COMPILE_OPTIONS}")

  # include directories, if no object library to provide them
  if (NOT DEFINED ARGS_SOURCES)
    set_target_properties(${target_name} PROPERTIES
      INCLUDE_DIRECTORIES "${include_dirs}")
  endif ()

  # custom component property
  if (DEFINED comp_arg)
    set_target_properties(${target_name} PROPERTIES ${comp_arg})
  endif ()

  # == Object Library ==

  # create library of exec's objects, allowing unit testing of exec's sources
  message(STATUS "debug ${ARGS_SOURCES}")
  if (DEFINED ARGS_SOURCES)
    message(STATUS "debug INSIDE ${ARGS_SOURCES}")
    add_library(${target_name}-objects OBJECT "${ARGS_SOURCES}")
    add_library(${target_name}-object-lib INTERFACE ${target_name}-objects)

    # properties on executable objects
    set_target_properties(${target_name}-objects PROPERTIES
      COMPILE_OPTIONS "${JGD_DEFAULT_COMPILE_OPTIONS}"
      INCLUDE_DIRECTORIES "${include_dirs}"
      INTERFACE_INCLUDE_DIRECTORIES "$<BUILD_INTERFACE:${include_dirs}>")

    target_link_libraries(${target_name} PRIVATE ${target_name}-object-lib)
  endif ()
endfunction()
