include_guard()

#[=======================================================================[.rst:

JcmAddOption
------------

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
      TYPE <BOOL|FILEPATH|PATH|STRING|INTERNAL>
      DEFAULT <default-value>
      DESCRIPTION <description>
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
   being in *SCREAMING_SNAKE_CASE*. The former provides consistency, clarify, and exclusivity of
   build options. However, this prefix check can be avoided with
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

:cmake:variable:`TYPE`
  The type of the option to create. Must be one of the `types available for cache entries
  <https://cmake.org/cmake/help/latest/command/set.html#set-cache-entry>`_: :cmake:`BOOL`,
  :cmake:`FILEPATH`, :cmake:`PATH`, :cmake:`STRING`, or :cmake:`INTERNAL`.

:cmake:variable:`DEFAULT`
  The default value of the option should it not already be set in the CMake cache. This value is
  also used if :cmake:variable:`CONDITION` is provided to this function but is not met.

:cmake:variable:`DESCRIPTION`
  A description of the option for builders of the project.

:cmake:variable:`CONDITION`
  An optional condition that will make the option a dependent option; dependent upon the provided
  condition. When provided, CMake's :cmake:variable:`cmake_dependent_option` will be used in place
  of :cmake:command:`set` to create the option.

:cmake:variable:`CONDITION_MET_DEFAULT`
  The default value of the option when :cmake:command:`CONDITION` is provided to this function and
  the condition is met. Like :cmake:variable:`DESCRIPTION`, when a value for the option already
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
    NAME ${PROJECT_NAME}_LINK_STATIC
    DESCRIPTION "Links the target ${PROJECT_NAME} exclusively against static libraries"
    TYPE BOOL
    DEFAULT OFF)

.. code-block:: cmake

  jcm_add_option(
    NAME ${PROJECT_NAME}_COMPRESSION_BACKEND
    DESCRIPTION "Selects the compression backend to use for transport compression"
    TYPE STRING
    DEFAULT "NONE"
    CONDITION "${PROJECT_NAME}_BUILD_TRANSPORT_LAYER"
    VALUES "NONE;ZIP;BROTLI;LZ")

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_add_option)
  jcm_parse_arguments(
    OPTIONS "WITHOUT_NAME_PREFIX_CHECK"
    ONE_VALUE_KEYWORDS "NAME" "TYPE" "DEFAULT" "DESCRIPTION" "CONDITION" "CONDITION_MET_DEFAULT"
    MULTI_VALUE_KEYWORDS "STRING_VALUES"
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
      "${ARGS_NAME}:${ARGS_TYPE}" "${ARGS_DESCRIPTION}"
      "${ARGS_CONDITION_MET_DEFAULT}"
      "${ARGS_CONDITION}"
      "${ARGS_DEFAULT}")
    set_property(CACHE "${ARGS_NAME}" PROPERTY TYPE "${ARGS_TYPE}")
  else()
    set(${ARGS_NAME} ${ARGS_DEFAULT} CACHE ${ARGS_TYPE} ${ARGS_DESCRIPTION})
  endif()

  if(DEFINED ARGS_ACCEPT_VALUES)
    set_property(CACHE "${ARGS_NAME}" PROPERTY STRINGS "${ARGS_ACCEPT_VALUES}")

    list(FIND "${ARGS_ACCEPT_VALUES}" "${${ARGS_NAME}}" accepted_index)
    if(accepted_index EQUAL -1)
      string(REPLACE ";" "|" pretty_accept_values "${ARGS_ACCEPT_VALUES}")
      message(FATAL_ERROR "Build option '${ARGS_NAME}' is restricted to one of "
        "'${pretty_accept_values}'. Its value, '${ARGS_NAME}', is not one of these")
    endif()
  endif()
endfunction()
