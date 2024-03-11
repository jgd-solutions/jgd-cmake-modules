include_guard()

#[=======================================================================[.rst:

JcmAddOption
------------

:github:`JcmAddOption`

#]=======================================================================]

include(JcmParseArguments)
include(JcmListTransformations)
include(CMakeDependentOption)

#[=======================================================================[.rst:

jcm_add_option
^^^^^^^^^^^^^^

.. cmake:command:: jcm_add_option

  .. code-block:: cmake

    jcm_add_option(
      [WITHOUT_NAME_PREFIX_CHECK]
      NAME <option-name>
      DESCRIPTION <description>
      TYPE <BOOL|FILEPATH|PATH|STRING|INTERNAL>
      DEFAULT <default-value>
      [CONDITION <condition>
       CONDITION_MET_DEFAULT <default-value-when-met>]
      [ACCEPT_VALUES <value>...])

Adds a project build-option using either :cmake:command:`set` or
:cmake:command:`cmake_dependent_option`, while providing better type support and validation. Like
the CMake built-ins to add options, :cmake:command:`option` and
:cmake:command:`cmake_dependent_option`, the options introduced by this function are just CACHE
variables that can be used to control the project's build.  As opposed to using either of those
CMake built-ins, this function provides:

#. Named arguments
#. Access to both independent and dependent build-options from a single function
#. Option types including those for dependent options, which :cmake:command:`cmake_dependent_option`
   does not support, and types beyond :cmake:`BOOL`, which is all that :cmake:command:`option`
   supports.
#. Validation of the option name being both prefixed by :cmake:`${JCM_PROJECT_PREFIX_NAME}_`, and
   being in *SCREAMING_SNAKE_CASE*. These provide consistency, clarity, and exclusivity of
   build options between projects. However, this prefix check can be avoided with
   :cmake:variable:`WITHOUT_NAME_PREFIX_CHECK`, for cases described in this parameter.
#. Limit the option value to one of :cmake:variable:`ACCEPT_VALUES`.

Parameters
##########

Options
~~~~~~~

:cmake:variable:`WITHOUT_NAME_PREFIX_CHECK`
  Skips the internal assertion that the provided option name, :cmake:variable:`NAME`, is prefixed
  with :cmake:`${JCM_PROJECT_PREFIX_NAME}_`. This would be used to create project agnostic options,
  like the common :cmake:variable:`BUILD_TESTING`. :cmake:variable:`BUILD_TESTING` is merely an
  example, as JCM will handle this specific option internally.

One Value
~~~~~~~~~

:cmake:variable:`NAME`
  The name of the option to create.

:cmake:variable:`DESCRIPTION`
  A description of the option for builders of the project.

:cmake:variable:`TYPE`
  The type of the option to create. Must be one of the `types available for cache entries
  <https://cmake.org/cmake/help/latest/command/set.html#set-cache-entry>`_: :cmake:`BOOL`,
  :cmake:`FILEPATH`, :cmake:`PATH`, :cmake:`STRING`, or :cmake:`INTERNAL`.

:cmake:variable:`DEFAULT`
  The default value of the option should it not already be set in the CMake cache. This value is
  also used if :cmake:variable:`CONDITION` is provided to this function but is not met.

:cmake:variable:`CONDITION`
  An optional condition that will make the option a dependent option; dependent upon the provided
  condition. When provided, CMake's :cmake:variable:`cmake_dependent_option` will be used in place
  of :cmake:command:`set` to create the option.

:cmake:variable:`CONDITION_MET_DEFAULT`
  The default value of the option when :cmake:variable:`CONDITION` is provided to this function and
  the condition is met. Like :cmake:variable:`DEFAULT`, when a value for the option already
  exists in the cache, it will be used in place of this default.

Multi Value
~~~~~~~~~~~

:cmake:variable:`ACCEPT_VALUES`
  Acceptable values of the created option. When provided, the :cmake:`STRINGS` property on the
  created cache entry will be set, and a fatal error will be emitted if the value of this option is
  not one of these declared values.

Examples
########

.. code-block:: cmake

  jcm_add_option(
    NAME ${PROJECT_NAME}_BUILD_INTEGRATION_TESTS
    DESCRIPTION "Builds the automated integration tests"
    TYPE BOOL
    DEFAULT ${PROJECT_NAME})

.. code-block:: cmake

  jcm_add_option(
    NAME ${PROJECT_NAME}_COMPRESSION_BACKEND
    DESCRIPTION "Selects the compression backend to use for transport compression"
    TYPE STRING
    DEFAULT "NONE"
    CONDITION "${PROJECT_NAME}_BUILD_TRANSPORT_LAYER"
    ACCEPT_VALUES "NONE;ZIP;BROTLI;LZ")

.. code-block:: cmake

    jcm_add_option(
      NAME BUILD_SHARED_LIBS
      DESCRIPTION "Build libraries with unspecified types shared."
      WITHOUT_NAME_PREFIX_CHECK
      TYPE BOOL
      DEFAULT OFF)

    jcm_add_option(
      NAME ${JCM_PROJECT_PREFIX_NAME}_BUILD_SHARED_LIBS
      DESCRIPTION "Build libraries of project ${PROJECT_NAME} with unspecified types shared."
      TYPE BOOL
      DEFAULT ${BUILD_SHARED_LIBS})

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_add_option)
  jcm_parse_arguments(
    OPTIONS "WITHOUT_NAME_PREFIX_CHECK"
    ONE_VALUE_KEYWORDS "NAME" "TYPE" "DEFAULT" "DESCRIPTION" "CONDITION" "CONDITION_MET_DEFAULT"
    MULTI_VALUE_KEYWORDS "ACCEPT_VALUES"
    REQUIRES_ALL "NAME" "TYPE" "DEFAULT" "DESCRIPTION"
    ARGUMENTS "${ARGN}")

  # Usage Guards
  set(supported_types "BOOL|FILEPATH|PATH|STRING|INTERNAL")
  if(NOT ARGS_TYPE MATCHES "${supported_types}")
    message(FATAL_ERROR
      "Argument 'TYPE' to ${CMAKE_CURRENT_FUNCTION} must name one of ${supported_types}. Instead, "
      "it names type '${ARGS_TYPE}'")
  endif()

  if(DEFINED ARGS_CONDITION AND NOT DEFINED ARGS_CONDITION_MET_DEFAULT)
    message(FATAL_ERROR
      "The argument 'CONDITION' must be accompanied by argument 'CONDITION_MET_DEFAULT' in "
      "function ${CMAKE_CURRENT_FUNCTION}")
  endif()

  if(NOT DEFINED ARGS_CONDITION AND DEFINED ARGS_CONDITION_MET_DEFAULT)
    message(AUTHOR_WARNING
      "Argument 'CONDITION_MET_DEFAULT' has no effect when argument 'CONDITION' isn't provided in "
      "function ${CMAKE_CURRENT_FUNCTION}")
  endif()

  # Option naming scheme
  set(expected_option_prefix "${JCM_PROJECT_PREFIX_NAME}_")
  if(NOT ARGS_WITHOUT_NAME_PREFIX_CHECK AND NOT ARGS_NAME MATCHES "^${expected_option_prefix}*")
    message(AUTHOR_WARNING
      "Options should present a common prefix for their associated project. Option '${ARGS_NAME}' "
      "should begin with '${expected_option_prefix}'")
  endif()

  if(NOT ARGS_NAME MATCHES "[A-Z]+[A-Z0-9_]*")
    message(AUTHOR_WARNING
      "Options be in screaming snake-case, which is all upper-case letters and numbers, with
      underscore separators. Option '${ARGS_NAME}' does not meet this standard.")
  endif()

  # TODO: verify provided default values based on type

  # Add Option
  if(DEFINED ARGS_CONDITION)
    cmake_dependent_option(
      "${ARGS_NAME}" "${ARGS_DESCRIPTION}"
      "${ARGS_CONDITION_MET_DEFAULT}"
      "${ARGS_CONDITION}"
      "${ARGS_DEFAULT}")
    set_property(CACHE "${ARGS_NAME}" PROPERTY TYPE "${ARGS_TYPE}")
  else()
    set(${ARGS_NAME} ${ARGS_DEFAULT} CACHE ${ARGS_TYPE} ${ARGS_DESCRIPTION})
  endif()

  if(DEFINED ARGS_ACCEPT_VALUES)
    set_property(CACHE "${ARGS_NAME}" PROPERTY STRINGS "${ARGS_ACCEPT_VALUES}")

    if(NOT "${${ARGS_NAME}}" IN_LIST ARGS_ACCEPT_VALUES)
      list(JOIN ARGS_ACCEPT_VALUES "|" pretty_accept_values)
      message(FATAL_ERROR "Build option '${ARGS_NAME}' is restricted to one of "
        "'${pretty_accept_values}'. Its value, '${${ARGS_NAME}}', is not one of these")
    endif()
  endif()
endfunction()


# Creates a build option named `${PROJECT_NAME}_ENABLE_<component>`, where component is a standard
# project component, i.e a library or executable component. An option will be created for every
# component in the list :cmake:variable:`OPTIONAL_COMPONENTS`. The result variables will contain all
# optional components that have been enabled via the respective build option, and all required
# components - those named in :cmake:variable:`REQUIRED_COMPONENTS`.
#



#[=======================================================================[.rst:

jcm_add_component_options
^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_add_component_options

  .. code-block:: cmake

    jcm_add_component_options(
      [REQUIRED_COMPONENTS <component>...]
      [DEFAULT_OFF_COMPONENTS <component>...]
      <OPTIONAL_COMPONENTS <component>...>
      <[OUT_COMPONENTS <out-var>] >
       [OUT_TARGETS <out-targets>] >)

Creates build options with :cmake:command:`jcm_add_option` named 
`${JCM_PROJECT_PREFIX_NAME}_ENABLE_<component>`, where *component* is the name of a standard project 
component, i.e a library or executable component. An option will be for every component in the list 
:cmake:variable:`OPTIONAL_COMPONENTS`. The result variables will contain all optional components 
that have been enabled by their respective build option, and all required components; those named 
in :cmake:variable:`REQUIRED_COMPONENTS`.

Every project component produces a single *installed* target. Targets can be selectively built by
CMake with the command-line option `--target`, such as `cmake --build build --target
libcomponents_libcomponents-core`, which will exclusively build the *core* component of project
*libcomponents*. However, the configuration of undesired components may also be worth avoiding if
their configuration is very long or introduces additional dependencies. For example, if the *extra*
component of *libcomponents* requires eight dependencies that aren't required by *core*, users of
*core* may not want to acquire dependencies they don't use. For this purpose, project options can be
introduced to selectively configure project components.

This function is merely a wrapper around :cmake:command`jcm_add_option` adding simplicity and
consistency for the use-case. Using this function does not preclude creating any project options 
through other means, nor do all project components need to be provided to this function.  

Component names cannot have any regex characters in them


Parameters
##########

Option
~~~~~~~~~

:cmake:variable:`OUT_COMPONENTS`
  The variable named will be set to the list of enabled components.


One Value
~~~~~~~~~

:cmake:variable:`OUT_COMPONENTS`
  The variable named will be set to the list of enabled components.

:cmake:variable:`OUT_TARGETS`
  The variable named will be set to the list of enabled targets derived from the enabled components 
  by prefixing each with `${PROJECT_NAME}::`.

Multi Value
~~~~~~~~~

:cmake:variable:`TYPE`
  The type of the option to create. Must be one of the `types available for cache entries
  <https://cmake.org/cmake/help/latest/command/set.html#set-cache-entry>`_: :cmake:`BOOL`,
  :cmake:`FILEPATH`, :cmake:`PATH`, :cmake:`STRING`, or :cmake:`INTERNAL`.

:cmake:variable:`DEFAULT`
  The default value of the option should it not already be set in the CMake cache. This value is
  also used if :cmake:variable:`CONDITION` is provided to this function but is not met.

:cmake:variable:`CONDITION`
  An optional condition that will make the option a dependent option; dependent upon the provided
  condition. When provided, CMake's :cmake:variable:`cmake_dependent_option` will be used in place
  of :cmake:command:`set` to create the option.

:cmake:variable:`CONDITION_MET_DEFAULT`
  The default value of the option when :cmake:variable:`CONDITION` is provided to this function and
  the condition is met. Like :cmake:variable:`DEFAULT`, when a value for the option already
  exists in the cache, it will be used in place of this default.

Multi Value
~~~~~~~~~~~

:cmake:variable:`REQUIRED_COMPONENTS`
  Optional list of project components that are always configured and do not have respective options to 
  disable them. The components named are always considered "enabled" and will appear unaltered
  in the variable named by :cmake:variable:`OUT_COMPONENTS`. This option is included to 
  declaratively indicate which components are required by a project, and make downstream handling
  of enabled components simpler.

:cmake:variable:`DEFAULT_OFF_COMPONENTS`
  Optional list of optional project components named in :cmake:variable:`REQUIRED_COMPONENTS` whose 
  respective build option should default of :cmake:`OFF`. All other build options will default to
  `ON`.

:cmake:variable:`OPTIONAL_COMPONENTS`
  Required list of optional project components that will have build options created for them.

Examples
########

.. code-block:: cmake

  jcm_add_component_options(
    REQUIRED_COMPONENTS "core"
    OPTIONAL_COMPONENTS "io" "extra" 
    DEFAULT_OFF_COMPONENTS "extra"
    OUT_COMPONENTS enabled_components)
    

--------------------------------------------------------------------------

#]=======================================================================]

function(jcm_add_component_options)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "OUT_TARGETS" "OUT_COMPONENTS"
    MULTI_VALUE_KEYWORDS "OPTIONAL_COMPONENTS" "REQUIRED_COMPONENTS" "DEFAULT_OFF_COMPONENTS"
    REQUIRES_ALL "OPTIONAL_COMPONENTS"
    REQUIRES_ANY "OUT_TARGETS" "OUT_COMPONENTS"
    ARGUMENTS "${ARGN}")

  if(DEFINED ARGS_REQUIRED_COMPONENTS)
    # ensure there is no overlap between required and optional components 
    set(required_regex "${ARGS_REQUIRED_COMPONENTS}")
    list(TRANSFORM required_regex PREPEND "^")
    list(TRANSFORM required_regex APPEND "$")
    list(JOIN required_regex "|" required_regex)

    set(overlapping_components "${ARGS_OPTIONAL_COMPONENTS}")
    list(FILTER overlapping_components INCLUDE REGEX "${required_regex}")
    if(overlapping_components)
      message(FATAL_ERROR
      "The following components are named as both OPTIONAL_COMPONENTS and REQUIRED_COMPONENTS: "
      "${overlapping_components}")
    endif()
  endif()

  if(DEFINED ARGS_DEFAULT_OFF_COMPONENTS)
    # ensure default off is subset of optional
    set(unknown_components "$${ARGS_DEFAULT_OFF_COMPONENTS}")
    list(REMOVE_ITEM unknown_components "${ARGS_OPTIONAL_COMPONENTS}")
    list(LENGTH unknown_components num_unknown)
    if(NOT unknown_components STREQUAL "0")
      message(FATAL_ERROR
      "The following components are mentioned in DEFAULT_OFF_COMPONENTS but are not named in "
      "OPTIONAL_COMPONENTS: ${overlapping_components}")

    endif()
  endif()

  set(option_names "${ARGS_OPTIONAL_COMPONENTS}")
  list(TRANSFORM option_names TOUPPER)
  list(TRANSFORM option_names PREPEND "${JCM_PROJECT_PREFIX_NAME}_ENABLE_")

  foreach(control IN ZIP_LISTS ARGS_OPTIONAL_COMPONENTS option_names)
    set(component "${control_0}")
    set(option_name "${control_1}")
    set(option_description
        [[Enables the configuration of project component ${component}. Useful to skip finding its \
          dependencies when ${PROJECT_NAME}::${component} is unused]])

    set(default_value ON)
    if("${component}" IN_LIST ARGS_DEFAULT_OFF_COMPONENTS)
      set(default_value OFF)
    endif()

    jcm_add_option(
      NAME "${option_name}"
      TYPE BOOL
      DEFAULT ${default_value}
      DESCRIPTION "${option_description}")
  endforeach()

  set(enabled_components "${ARGS_REQUIRED_COMPONENTS}")
  foreach(control IN ZIP_LISTS ARGS_OPTIONAL_COMPONENTS option_names)
    set(component "${control_0}")
    set(option_name "${control_1}")
    if(${option_name})
      list(APPEND enabled_components "${component}")
    endif()
  endforeach()

  if(DEFINED ARGS_OUT_COMPONENTS)
    set(${ARGS_OUT_COMPONENTS} "${enabled_components}" PARENT_SCOPE)
  endif()

  if(DEFINED ARGS_OUT_TARGETS)
    list(TRANSFORM enabled_components PREPEND "${PROJECT_NAME}::")
    set(${ARGS_OUT_TARGETS} "${enabled_components}" PARENT_SCOPE)
  endif()
endfunction()
