#[=======================================================================[.rst:

JcmFileNaming
-------------

Provides variables and functions to help enforce file naming conventions.

For each of the enabled languages at the point of inclusion, as per the global `ENABLED_LANGUAGES`
property, the following variables are defined. These contain regular expressions for suitable file
names for the given language. Supported languages are currently C,CXX,CUDA,OBJC,OBJCXX,HIP

- :cmake:variable:`JCM_<LANG>_HEADER_REGEX`
- :cmake:variable:`JCM_<LANG>_SOURCE_REGEX`
- :cmake:variable:`JCM_<LANG>_TEST_SOURCE_REGEX`

The following variables provide cumulative regular expressions for all the enabled languages
encountered to the point of inclusion. These are built by joining the variables above with the '|'
character.

- :cmake:variable:`JCM_HEADER_REGEX`
- :cmake:variable:`JCM_SOURCE_REGEX`
- :cmake:variable:`JCM_TEST_SOURCE_REGEX`

Additional, non-languages specific variables with regular expressions for file names are introduced:

- :cmake:variable:`JCM_CMAKE_MODULE_REGEX`. This is for normal CMake modules, not package-config files.
- :cmake:variable:`JCM_IN_FILE_REGEX`
- :cmake:variable:`JCM_CXX_MODULE_REGEX`

--------------------------------------------------------------------------

#]=======================================================================]

include(JcmCanonicalStructure)

# non-package-config cmake modules
set(JCM_CMAKE_MODULE_REGEX "^([A-Z][a-z]*)+\\.cmake$")
set(JCM_IN_FILE_REGEX "\\${JCM_IN_FILE_EXTENSION}$")

# Create regexs of file names based on file extensions from JcmCanonicalStructure.
# Variables of the same name, but with _EXTENSION replaced with _REGEX
foreach (ext_var
    JCM_CXX_HEADER_EXTENSION JCM_CXX_SOURCE_EXTENSION JCM_CXX_TEST_SOURCE_EXTENSION JCM_CXX_MODULE_EXTENSION
    JCM_C_HEADER_EXTENSION JCM_C_SOURCE_EXTENSION JCM_C_TEST_SOURCE_EXTENSION
    JCM_CUDA_HEADER_EXTENSION JCM_CUDA_SOURCE_EXTENSION JCM_CUDA_TEST_SOURCE_EXTENSION
    JCM_OBJC_HEADER_EXTENSION JCM_OBJC_SOURCE_EXTENSION JCM_OBJC_TEST_SOURCE_EXTENSION
    JCM_OBJCXX_HEADER_EXTENSION JCM_OBJCXX_SOURCE_EXTENSION JCM_OBJCXX_TEST_SOURCE_EXTENSION
    JCM_HIP_HEADER_EXTENSION JCM_HIP_SOURCE_EXTENSION JCM_HIP_TEST_SOURCE_EXTENSION)

  string(REPLACE "_EXTENSION" "_REGEX" regex_var "${ext_var}")
  string(REPLACE "." "\\." ${regex_var} "${${ext_var}}")
  set(${regex_var} "^[a-z][a-z0-9_]*${${regex_var}}$")
endforeach ()

# Create cumulative regexes for all currently enabled languages
get_property(_jcm_languages GLOBAL PROPERTY ENABLED_LANGUAGES)
if(_jcm_languages)
  list(REMOVE_ITEM _jcm_languages ${_jcm_already_enabled_languages} NONE)
endif()

if(_jcm_languages)
  foreach(lang IN LISTS _jcm_languages)
    if(NOT "${lang}" MATCHES "CXX|C|CUDA|OBJC|OBJCXX|HIP")
      message(AUTHOR_WARNING
          "The enabled languages '${lang}' is not currently supported by JCM."
          "The associated REGEX variables will not be created")
      continue()
    endif()

    list(APPEND JCM_HEADER_REGEX "${JCM_${lang}_HEADER_REGEX}")
    list(APPEND JCM_SOURCE_REGEX "${JCM_${lang}_SOURCE_REGEX}")
    list(APPEND JCM_TEST_SOURCE_REGEX "${JCM_${lang}_TEST_SOURCE_REGEX}")
    list(APPEND _jcm_already_enabled_languages ${lang})
  endforeach()

  list(REMOVE_DUPLICATES JCM_HEADER_REGEX)
  list(REMOVE_DUPLICATES JCM_SOURCE_REGEX)
  list(REMOVE_DUPLICATES JCM_TEST_SOURCE_REGEX)
  list(JOIN JCM_HEADER_REGEX "|" JCM_HEADER_REGEX)
  list(JOIN JCM_SOURCE_REGEX "|" JCM_SOURCE_REGEX)
  list(JOIN JCM_TEST_SOURCE_REGEX "|" JCM_TEST_SOURCE_REGEX)
endif()

unset(_jcm_languages)


include_guard()

include(JcmParseArguments)

#
# Private macro to the module. Constructs a consistent file name based on the PROJECT argument or
# the PROJECT_NAME variable, the provided COMPONENT, and SUFFIX arguments. The resulting file name
# will be placed in the variable specified by OUT_VAR. Result will be
# <PROJECT_NAME><DELIMITER>[COMPONENT<DELIMETER>]<suffix>, where 'suffix' is the provided suffix
# with any leading dashes removed. DELIMITER is '-', by default.
#
macro(_JCM_JOINED_FILE_NAME)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "COMPONENT;DELIMITER;SUFFIX;PROJECT;OUT_VAR"
    REQUIRES_ALL "SUFFIX;OUT_VAR"
    ARGUMENTS "${ARGN}")

  # project name
  if (DEFINED ARGS_PROJECT)
    set(project ${ARGS_PROJECT})
  else ()
    set(project ${PROJECT_NAME})
  endif ()

  if (DEFINED ARGS_DELIMITER)
    set(delim ${ARGS_DELIMITER})
  else ()
    set(delim "-")
  endif ()

  # remove leading delimiters from suffix
  string(REGEX REPLACE "^${delim}" "" suffix "${ARGS_SUFFIX}")

  # compose file name
  if (NOT ARGS_COMPONENT OR (ARGS_COMPONENT STREQUAL project))
    set(${ARGS_OUT_VAR} "${project}${delim}${suffix}" PARENT_SCOPE)
  else ()
    set(
      ${ARGS_OUT_VAR}
      "${project}${delim}${ARGS_COMPONENT}${delim}${suffix}"
      PARENT_SCOPE
    )
  endif ()

  unset(suffix)
  unset(delim)
  unset(project)
endmacro()

# handles parsing arguments for the following *_file_name commands, as they all accept similar
# arguments.
macro(_JCM_FILE_NAMING_ARGUMENTS with_component args)
  if (${with_component})
    set(comp_keyword COMPONENT)
  else()
    unset(comp_keyword)
  endif ()

  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "${comp_keyword};PROJECT;OUT_VAR"
    REQUIRES_ALL "OUT_VAR"
    ARGUMENTS "${args}"
  )
  if (DEFINED ARGS_PROJECT)
    set(proj_arg PROJECT ${ARGS_PROJECT})
  else()
    unset(proj_arg)
  endif ()

  if (DEFINED ARGS_COMPONENT)
    set(comp_arg COMPONENT ${ARGS_COMPONENT})
  else()
    unset(comp_arg)
  endif ()
endmacro()

#[=======================================================================[.rst:

jcm_package_config_file_name
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_package_config_file_name

  .. code-block:: cmake

    jcm_package_config_file_name(
      [PROJECT <project>]
      [COMPONENT <component>]
      OUT_VAR <out-var>
    )

Constructs a consistent kebab-case package configuration file name based on the
:cmake:variable:`PROJECT`, which defaults to :cmake:variable:`PROJECT_NAME`, and
:cmake:variable:`COMPONENT`, if provided.  The resulting file name will be placed in the variable
specified by :cmake:variable:`OUT_VAR`. Result will be `<PROJECT>-[COMPONENT-]config.cmake`.

Parameters
##########

One Value
~~~~~~~~~

:cmake:variable:`PROJECT`
  The project that the config-file packages, if the default value of :cmake:variable:`PROJECT_NAME`
  is not correct.

:cmake:variable:`COMPONENT`
  Specifies the component that the file will describe. A :cmake:variable:`COMPONENT` that matches
  :cmake:variable:`PROJECT_NAME` or :cmake:variable:`PROJECT` will be ignored.

:cmake:variable:`OUT_VAR`
  The variable named will be set to the resultant file name

Examples
########

.. code-block:: cmake

  # PROJECT_NAME is libgarden
  # file_name will be libgarden-config.cmake
  jcm_package_config_file_name(OUT_VAR file_name)

.. code-block:: cmake

  # file_name will be libimage-core-config.cmake
  jcm_package_config_file_name(
    PROJECT libimage
    COMPONENT core
    OUT_VAR file_name
  )

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_package_config_file_name)
  _jcm_file_naming_arguments(TRUE "${ARGN}")
  _jcm_joined_file_name(
    ${proj_arg}
    ${comp_arg}
    SUFFIX "config.cmake"
    OUT_VAR "${ARGS_OUT_VAR}"
  )
endfunction()

#[=======================================================================[.rst:

jcm_package_version_file_name
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_package_version_file_name

  .. code-block:: cmake

    jcm_package_version_file_name(
      [PROJECT <project>]
      OUT_VAR <out-var>
    )

Constructs a consistent kebab-case package version file name based on the :cmake:variable:`PROJECT`,
which defaults to :cmake:variable:`PROJECT_NAME`. The resulting file name will be placed in the
variable specified by :cmake:variable:`OUT_VAR`. Result will be `<PROJECT>-version.cmake`.

Parameters
##########

One Value
~~~~~~~~~

:cmake:variable:`PROJECT`
  The project that the version file represents, if the default value of
  :cmake:variable:`PROJECT_NAME` is not correct.

:cmake:variable:`OUT_VAR`
  The variable named will be set to the resultant file name

Examples
########

.. code-block:: cmake

  # PROJECT_NAME is libgarden
  # file_name will be libgarden-version.cmake
  jcm_package_version_file_name(OUT_VAR file_name)

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_package_version_file_name)
  _jcm_file_naming_arguments(FALSE "${ARGN}")
  _jcm_joined_file_name(
    ${proj_arg}
    SUFFIX "config-version.cmake"
    OUT_VAR "${ARGS_OUT_VAR}"
  )
endfunction()

#
# Constructs a consistent kebab-case targets file name based on the PROJECT
# argument or the PROJECT_NAME variable. Targets
# files are part of 'config-file' packages. The resulting file name will be
# placed in the variable specified by OUT_VAR. The result will be
# <PROJECT_NAME>-targets.cmake. Ex. proj-targets.cmake.
#
# Arguments:
#
# PROJECT: on-value arg; override of PROJECT_NAME. Optional - if not provided,
# PROJECT_NAME will be used, which is more common.
#
# OUT_VAR: one-value arg; the name of the output variable which will store the
# resulting file name.
#

#[=======================================================================[.rst:

jcm_package_targets_file_name
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_package_targets_file_name

  .. code-block:: cmake

    jcm_package_targets_file_name(
      [PROJECT <project>]
      [COMPONENT <component>]
      OUT_VAR <out-var>
    )

Constructs a consistent kebab-case package targets file name based on the :cmake:variable:`PROJECT`,
which defaults to :cmake:variable:`PROJECT_NAME`, and :cmake:variable:`COMPONENT`, if provided.  The
resulting file name will be placed in the variable specified by :cmake:variable:`OUT_VAR`. Result
will be `<PROJECT>-[COMPONENT-]targets.cmake`. The target's file naming scheme includes a component
because JCM installs one targets file per target for simpler management.

Parameters
##########

One Value
~~~~~~~~~

:cmake:variable:`PROJECT`
  The project that the targets file contains targets for, if the default value of
  :cmake:variable:`PROJECT_NAME` is not correct.

:cmake:variable:`COMPONENT`
  Specifies the component that the file will describe. A :cmake:variable:`COMPONENT` that matches
  :cmake:variable:`PROJECT_NAME` or :cmake:variable:`PROJECT` will be ignored.

:cmake:variable:`OUT_VAR`
  The variable named will be set to the resultant file name

Examples
########

.. code-block:: cmake

  # PROJECT_NAME is libgarden
  # file_name will be libgarden-targets.cmake
  jcm_package_targets_file_name(OUT_VAR file_name)

.. code-block:: cmake

  # file_name will be libimage-core-targets.cmake
  jcm_package_targets_file_name(
    PROJECT libimage
    COMPONENT core
    OUT_VAR file_name
  )

--------------------------------------------------------------------------

#]=======================================================================]
function(jcm_package_targets_file_name)
  _jcm_file_naming_arguments(TRUE "${ARGN}")
  _jcm_joined_file_name(
    ${proj_arg}
    ${comp_arg}
    SUFFIX "targets.cmake"
    OUT_VAR ${ARGS_OUT_VAR}
  )
endfunction()
