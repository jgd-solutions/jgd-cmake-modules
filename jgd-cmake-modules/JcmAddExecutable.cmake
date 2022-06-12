include_guard()

include(JcmParseArguments)
include(JcmFileNaming)
include(JcmTargetNaming)
include(JcmSeparateList)
include(JcmCanonicalStructure)
include(JcmDefaultCompileOptions)

# again, artifacts
function(jcm_add_executable)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS
    "COMPONENT;EXECUTABLE;OUT_TARGET_NAME"
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
  else()
    unset(comp_arg)
    unset(comp_err_msg)
  endif ()

  # == Usage Guards ==

  # ensure executable is created in the appropriate canonical directory
  jcm_canonical_exec_subdir(${comp_arg} OUT_VAR canonical_dir)
  if (NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL canonical_dir)
    message(
      FATAL_ERROR
      "Creating a${comp_err_msg} executable for project ${PROJECT_NAME} must "
      "be done in the canonical directory ${canonical_dir}.")
  endif ()

  # verify source naming
  set(regex "${JCM_HEADER_REGEX}|${JCM_SOURCE_REGEX}")
  jcm_separate_list(
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
    jcm_executable_naming(
      ${comp_arg}
      OUT_TARGET_NAME target_name
      OUT_EXPORT_NAME export_name
      OUT_OUTPUT_NAME output_name)
  endif ()

  if (DEFINED ARGS_OUT_TARGET_NAME)
    set(${ARGS_OUT_TARGET_NAME} ${target_name} PARENT_SCOPE)
  endif ()

  # create executable target
  add_executable(${target_name} "${ARGS_MAIN_SOURCES}")
  add_executable(${PROJECT_NAME}::${export_name} ALIAS ${target_name})

  # == Set Target Properties ==

  jcm_canonical_include_dirs(TARGET ${target_name} OUT_VAR include_dirs)

  # basic properties
  set_target_properties(${target_name}
    PROPERTIES OUTPUT_NAME ${output_name}
    EXPORT_NAME ${export_name}
    COMPILE_OPTIONS "${JCM_DEFAULT_COMPILE_OPTIONS}")

  # include directories, if no object library will be created to provide them
  if (NOT DEFINED ARGS_SOURCES)
    target_include_directories(${target_name} PRIVATE "$<BUILD_INTERFACE:${include_dirs}>")
  endif ()

  # custom component property
  if (DEFINED comp_arg)
    set_target_properties(${target_name} PROPERTIES ${comp_arg})
  endif ()

  # == Object Library ==

  # create library of exec's objects, allowing unit testing of exec's sources
  if (DEFINED ARGS_SOURCES)
    add_library(${target_name}-objects OBJECT "${ARGS_SOURCES}")

    # properties on executable objects
    target_compile_options(${target_name}-objects PRIVATE "${JCM_DEFAULT_COMPILE_OPTIONS}")
    target_include_directories(${target_name}-objects PUBLIC "$<BUILD_INTERFACE:${include_dirs}>")

    # link target to associated object files & usage requirements
    target_link_libraries(${target_name} PRIVATE ${target_name}-objects)
  endif ()
endfunction()