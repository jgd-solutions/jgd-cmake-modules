include_guard()

#[=======================================================================[.rst:

JcmTargetNaming
---------------

#]=======================================================================]

include(JcmParseArguments)
include(JcmCanonicalStructure)

#[=======================================================================[.rst:

jcm_library_naming
^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_library_naming

  .. code-block:: cmake

    jcm_library_naming(
      [PROJECT <project-name>]
      [COMPONENT <component>]
      (OUT_TARGET <target> |
       OUT_EXPORT_NAME <out-var>
       OUT_OUTPUT_NAME <out-var>)
    )


Sets the output variable specified by the *OUT_** arguments to default,
consistent, unique library names that libraries can use to initialize their
naming properties.

Parameters
##########

One Value
~~~~~~~~~

:cmake:variable:`PROJECT`
  The project to which the library belongs. The project name is used in the library names to ensure
  uniqueness in super-builds. :cmake:variable:`PROJECT_NAME` will be used by default.

:cmake:variable:`COMPONENT`
  The project component that this library represents. The component is used in the library names.

:cmake:variable:`OUT_TARGET`
  The variable named will be set to the resultant target name for a library of the specified project
  that provides the specified component.

:cmake:variable:`OUT_EXPORT_NAME`
  The variable named will be set to the resultant export name for the library, that should be used
  to initialize the *EXPORT_NAME* target property.

:cmake:variable:`OUT_OUTPUT_NAME`
  The variable named will be set to the resultant export name for the library, that should be used
  to initialize the *OUTPUT_NAME* target property.

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_library_naming)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS
    "PROJECT"
    "COMPONENT"
    "OUT_TARGET"
    "OUT_EXPORT_NAME"
    "OUT_OUTPUT_NAME"
    REQUIRES_ANY
    "OUT_TARGET"
    "OUT_EXPORT_NAME"
    "OUT_OUTPUT_NAME"
    ARGUMENTS "${ARGN}"
  )

  # Resolve project name
  if(ARGS_PROJECT)
    set(project_name ${ARGS_PROJECT})
  else()
    set(project_name ${PROJECT_NAME})
  endif()

  # Resolve component
  if (DEFINED ARGS_COMPONENT AND NOT ARGS_COMPONENT STREQUAL project_name)
    set(component ${ARGS_COMPONENT})
  else()
    unset(component)
  endif ()

  # Base name upon which library names will be derived
  string(REGEX REPLACE "^${JCM_LIB_PREFIX}" "" no_prefix ${project_name})
  set(base_name "${JCM_LIB_PREFIX}${no_prefix}")
  if (DEFINED component)
    string(APPEND base_name "-${component}")
  endif ()

  # Export name
  if (DEFINED ARGS_OUT_EXPORT_NAME)
    # there's a component and the project starts with JCM_LIB_PREFIX
    if (DEFINED component AND NOT no_prefix STREQUAL project_name)
      set(${ARGS_OUT_EXPORT_NAME} ${component} PARENT_SCOPE)
    else ()
      set(${ARGS_OUT_EXPORT_NAME} ${base_name} PARENT_SCOPE)
    endif ()
  endif ()

  # Output name
  if (DEFINED ARGS_OUT_OUTPUT_NAME)
    set(${ARGS_OUT_OUTPUT_NAME} ${base_name} PARENT_SCOPE)
  endif ()

  # Target name
  if (DEFINED ARGS_OUT_TARGET)
    # prepend project name to avoid possible conflicts if added as subdirectory
    set(${ARGS_OUT_TARGET} ${project_name}_${base_name} PARENT_SCOPE)
  endif ()
endfunction()


#[=======================================================================[.rst:

jcm_executable_naming
^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_executable_naming

  .. code-block:: cmake

    jcm_executable_naming(
      [PROJECT <project-name>]
      [COMPONENT <component>]
      (OUT_TARGET <target> |
       OUT_EXPORT_NAME <out-var>
       OUT_OUTPUT_NAME <out-var>)
    )


Sets the output variable specified by the *OUT_** arguments to default, consistent, unique
executables names that executables can use to initialize their naming properties.

Parameters
##########

One Value
~~~~~~~~~

:cmake:variable:`PROJECT`
  The project to which the executable belongs. The project name is used in the executable names to
  ensure uniqueness in super-builds. :cmake:variable:`PROJECT_NAME` will be used by default.

:cmake:variable:`COMPONENT`
  The project component that this executable represents. The component is used in the executable
  names.

:cmake:variable:`OUT_TARGET`
  The variable named will be set to the resultant target name for an executable of the specified
  project that provides the specified component.

:cmake:variable:`OUT_EXPORT_NAME`
  The variable named will be set to the resultant export name for the executable, that should be
  used to initialize the *EXPORT_NAME* target property.

:cmake:variable:`OUT_OUTPUT_NAME`
  The variable named will be set to the resultant export name for the executable, that should be used
  to initialize the *OUTPUT_NAME* target property.

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_executable_naming)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS
    "PROJECT"
    "COMPONENT"
    "OUT_TARGET"
    "OUT_EXPORT_NAME"
    "OUT_OUTPUT_NAME"
    REQUIRES_ANY
    "OUT_TARGET"
    "OUT_EXPORT_NAME"
    "OUT_OUTPUT_NAME"
    ARGUMENTS "${ARGN}"
  )

  # Resolve project name
  if(ARGS_PROJECT)
    set(project_name ${ARGS_PROJECT})
  else()
    set(project_name ${PROJECT_NAME})
  endif()

  # Resolve component
  if (DEFINED ARGS_COMPONENT AND NOT ARGS_COMPONENT STREQUAL project_name)
    set(component ${ARGS_COMPONENT})
  else()
    unset(component)
  endif ()

  # Base name upon which executable names will be derived
  string(REGEX REPLACE "^${JCM_LIB_PREFIX}" "" no_prefix ${project_name})
  set(base_name ${no_prefix})
  if (DEFINED component)
    string(APPEND base_name "-${component}")
  endif ()

  # Export name
  if (DEFINED ARGS_OUT_EXPORT_NAME)
    # there's a component and the project doesn't start with JCM_LIB_PREFIX
    if (DEFINED component AND no_prefix STREQUAL project_name)
      set(${ARGS_OUT_EXPORT_NAME} ${component} PARENT_SCOPE)
    else ()
      set(${ARGS_OUT_EXPORT_NAME} ${base_name} PARENT_SCOPE)
    endif ()
  endif ()

  # Output name
  if (DEFINED ARGS_OUT_OUTPUT_NAME)
    set(${ARGS_OUT_OUTPUT_NAME} ${base_name} PARENT_SCOPE)
  endif ()

  # Target name
  if (DEFINED ARGS_OUT_TARGET)
    # prepend project name to avoid possible conflicts if added as subdirectory
    set(${ARGS_OUT_TARGET} ${project_name}_${base_name} PARENT_SCOPE)
  endif ()
endfunction()


#[=======================================================================[.rst:

jcm_target_type_component_from_name
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_target_type_component_from_name

  .. code-block:: cmake

    jcm_target_type_component_from_name(
      [PROJECT <project-name>]
      TARGET_NAME <target>
      (OUT_TYPE <target> |
       OUT_COMPONENT <out-var>)
    )

JCM's target naming conventions denote both the the target's type and component within the naming
structure. This function will, considering the project name, compute the target type and component
from a given target name. The named target doesn't have to exist.

Parameters
##########

One Value
~~~~~~~~~

:cmake:variable:`PROJECT`
  The project to which the target belongs. Since project names are embedded within target names, it
  must be known in deduction. :cmake:variable:`PROJECT_NAME` will be used by default.

:cmake:variable:`TARGET_NAME`
  A target name following JCM's target naming conventions that the target type and component will be
  computed from.

:cmake:variable:`OUT_TYPE`
  The variable named will store the computed target type

:cmake:variable:`OUT_COMPONENT`
  The variable named will store the computed component or an empty string if the target is not a
  project component.

Examples
########

.. code-block:: cmake

  jcm_target_type_component_from_name(
    PROJECT libssh
    TARGET_NAME libssh::libssh
    TARGET_TYPE type
    TARGET_COMPONENT component
  )

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_target_type_component_from_name)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "PROJECT" "TARGET_NAME" "OUT_TYPE" "OUT_COMPONENT"
    REQUIRES_ALL "TARGET_NAME"
    REQUIRES_ANY "OUT_TYPE" "OUT_COMPONENT"
    ARGUMENTS "${ARGN}")

  # Resolve project name
  if(ARGS_PROJECT)
    set(project_name ${ARGS_PROJECT})
  else()
    set(project_name ${PROJECT_NAME})
  endif()

  # Usage guards
  if(NOT ARGS_TARGET_NAME MATCHES "^${project_name}(::|_)")
    message(FATAL_ERROR "TARGET_NAME provided to ${CMAKE_CURRENT_FUNCTION} does not start with "
      "'${project_name}::' or '${project_name}_' and does therefore not follow the target naming "
      "structure or is not part of project ${project_name}. Target type and component cannot be "
      "deduced from the name '${ARGS_TARGET_NAME}'")
  endif()

  if(TARGET ARGS_TARGET_NAME)
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} is designed for target names, when the target "
        "does not exist. '${ARGS_TARGET}' is a target and its properties need to be read instead.")
  endif()

  if(ARGS_TARGET_NAME MATCHES "::") # alias
    string(REGEX REPLACE "^${project_name}::" "" base_name "${ARGS_TARGET_NAME}")
  else()
    string(REGEX REPLACE "^${project_name}_" "" base_name "${ARGS_TARGET_NAME}")
  endif()

  string(REGEX REPLACE "^${JCM_LIB_PREFIX}" "" proj_no_lib "${project_name}")
  string(REGEX REPLACE "^${JCM_LIB_PREFIX}" "" name_no_lib "${base_name}")
  string(REGEX REPLACE ".*-" "" name_ending "${base_name}") # possibly the component name

  set(type)
  set(component)

  # executable proj
  if(proj_no_lib STREQUAL project_name)
    if(name_no_lib STREQUAL base_name)    # executable target
      set(type "EXECUTABLE")
      if(NOT base_name STREQUAL project_name) # executable component target
        set(component "${base_name}")
      endif()
    else()                                   # library target
      set(type "LIBRARY")
      if(NOT name_ending STREQUAL base_name) # library component target
        set(component "${name_ending}")
      endif()
    endif()

  # library project
  else()
    if(base_name MATCHES "^${proj_no_lib}")  # executable target
      set(type "EXECUTABLE")
      if(NOT name_ending STREQUAL base_name) # executable component target
        set(component "${name_ending}")
      endif()
    else()                                    # library target
      set(type "LIBRARY")
      if(NOT base_name STREQUAL project_name) # library component target
        set(component "${base_name}")
      endif()
    endif()
  endif()

  # Set output variables
  if(DEFINED ARGS_OUT_TYPE)
    set(${ARGS_OUT_TYPE} ${type} PARENT_SCOPE)
  endif()

  if(DEFINED ARGS_OUT_COMPONENT)
    set(${ARGS_OUT_COMPONENT} "${component}" PARENT_SCOPE)
  endif()
endfunction()
