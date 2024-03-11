#[=======================================================================[.rst:

JcmArbitraryScript
------------------

:github:`JcmArbitraryScript`

In most cases, CMake will reconfigure as necessary to update targets and files when it detects
changes. However, it's sometimes necessary to enact some action as part of the project's build phase
as opposed to its configure phase. This is often achieved in multiple steps by first generating the
desired script at configure time, and then creating targets with commands that invoke an interpreter
on that script, like `cmake -P ...`, `bash`, or `python`. 

This module is designed to act as the generated script from configure time, but instead of
containing specific code, it directly evaluates the CMake code provided in a command-line argument,
thereby allowing it to evaluate any arbitrary CMake code. Executing `cmake -P
/path/to/JcmArbitraryScript.cmake -- '<cmake code>'` provides behaviour equivalent to `bash -c
'<bash code>'` or `node -e '<javascript code>'`. Although this module was created with the intention
of simplifying invocations of scripts in the generated buildsystem, it fundamentally allows `cmake
-P` to accept code as a string instead of from a file.

Additionally provided in this module is :cmake:command:`jcm_form_arbitrary_script_command()`, which
allows easily and consistently creating a CMake command at configure-time to invoke arbitrary CMake
code at build-time by interpreting this file in script mode. `That function
<#jcm-form-arbitrary-script-command>`_ should be the primary interface through which this module is
used. Examples of direct use follows. Note that escape sequences are interpreted by this script.

.. code-block:: bash

  cmake -P /path/to/jgd-cmake-modules/JcmArbitraryScript.cmake --
    'message("first\ command")\n\ message("second\ command")'

--------------------------------------------------------------------------

#]=======================================================================]

if(CMAKE_SCRIPT_MODE_FILE STREQUAL CMAKE_CURRENT_LIST_FILE)
  # Argument validation.
  # Expect separator and a single argument following that containing the code to evaluate.
  set(separator_arg_idx "${CMAKE_ARGC}")
  foreach(arg_idx RANGE 2 "${CMAKE_ARGC}")
    set(arg "${CMAKE_ARGV${arg_idx}}")
    if(arg STREQUAL "--")
      set(separator_arg_idx "${arg_idx}")
      break()
    endif()
  endforeach()

  set(base_invalid_arg_message
      "JcmArbitraryScript.cmake invoked in script mode expects the separator '--' to be present, \
      followed by a single argument containing the cmake code to evaluate. ")
  if(separator_arg_idx STREQUAL "${CMAKE_ARGC}")
    message(FATAL_ERROR "${base_invalid_arg_message}" "The separator is not present.")
  endif()

  math(EXPR last_arg_idx "${CMAKE_ARGC} - 1")
  math(EXPR separated_arg_count "${last_arg_idx} - ${separator_arg_idx}")
  set(code "${CMAKE_ARGV${last_arg_idx}}")
  if(separator_arg_idx STREQUAL last_arg_idx)
    message(FATAL_ERROR "${base_invalid_arg_message}" "No arguments follow the separator.")
  elseif(NOT separated_arg_count STREQUAL "1")
    message(FATAL_ERROR
      "${base_invalid_arg_message}" "Multiple (${separated_arg_count}) arguments follow the separator.")
  endif()

  # Evaluate code
  # interpret all escape sequences as their control characters
  string(REPLACE \\n \n code "${code}")
  string(REPLACE \\r \r code "${code}")
  string(REPLACE \\t \t code "${code}")
  string(REPLACE \\' ' code "${code}")
  string(REPLACE \\\" \" code "${code}")
  string(REPLACE \\\\ \\ code "${code}")
  string(REPLACE "\\ " " " code "${code}")
  cmake_language(EVAL CODE "${code}")
  return()
endif()



include_guard()

include(JcmParseArguments)

#[=======================================================================[.rst:

jcm_form_arbitrary_script_command
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_form_arbitrary_script_command 

  .. code-block:: cmake

    jcm_form_arbitrary_script_command(
      OUT_VAR <out-var>
      CODE <cmake-code>...)

Forms a command that is suitable for use as a :cmake:variable:`COMMAND` argument to functions such
as :cmake:command:`add_custom_command()` that will evaluate the provided :cmake:variable:`CODE` when
executed. This is useful to invoke arbitrary code in the build-phase of a project without having to
generate intermediate script files or the commands to invoke interpreters on them.

Escape sequences in the :cmake:variable:`CODE` strings will be preserved by escaping their backslash
and control characters will be escaped to become escape sequences. This ensures control characters
aren't interpreted by CMake as it generates the buildsystem or the buildsystem itself, as these
would create malformed build files. Escape sequences are then interpreted by
JcmArbitraryScript.cmake to unwind the escaping introduced here.

Parameters
##########

One Value
~~~~~~~~~

:cmake:variable:`OUT_VAR`
  The variable named will be set to the resultant command that is suitable for use as a
  :cmake:variable:`COMMAND` argument to functions such as :cmake:command:`add_custom_command()`.
  This will always be a semicolon separated list.


Multi Value
~~~~~~~~~~~

:cmake:variable:`CODE`
  Collection of CMake code that will be joined and evaluated by CMake when the command is executed

Examples
########

.. code-block:: cmake

  # adapted from `jcm_create_message_target`_ to emit a message at build-time
  set(log_level "WARNING")
  set(message_text "hello")
  list(APPEND message_text ", goodby")

  jcm_form_arbitrary_script_command(
    OUT_VAR message_command
    CODE "message(${log_level}" "${messages})")

  add_custom_target(build_time_message ALL COMMAND "${message_command}")

.. code-block:: cmake

  # a contrived example invoking JCM modules in a command at build-time

  jcm_form_arbitrary_script_command(
    OUT_VAR ensure_symlink_command 
    CODE [[
    cmake_minimum_required(VERSION ${CMAKE_MINIMUM_REQUIRED_VERSION})
    set(jgd-cmake-modules_DIR "${jgd-cmake-modules_DIR}")
    find_package(jgd-cmake-modules CONFIG REQUIRED)
    include(JcmSymlinks)
    jcm_check_symlinks_available(OUT_ERROR_MESSAGE symlink_err_message)
    if(symlink_err_message)
      message(FATAL_ERROR "${symlink_err_message}")
    endif()
  ]])

  add_custom_target(do_configure 
    COMMAND "${ensure_symlink_command}"
    COMMAND 
      "${CMAKE_COMMAND}" -E create_symlink 
      /usr/local/lib/node_modules /usr/local/lib/node_modules)

#]=======================================================================]
function(jcm_form_arbitrary_script_command)
  jcm_parse_arguments(
    OPTIONS "WITHOUT_WINDOWS_POWERSHELL"
    ONE_VALUE_KEYWORDS "OUT_VAR"
    MULTI_VALUE_KEYWORDS "CODE"
    REQUIRES_ALL "OUT_VAR" "CODE"
    ARGUMENTS "${ARGN}")

  list(JOIN ARGS_CODE "" code)

  # - any existing escape sequences must have their '\' escaped to preserve the sequence
  string(REPLACE \\ \\\\ code "${code}")

  # - any control characters must be converted into escape sequences
  # avoid interpretation by CMake generation, or the build-system itself
  string(REPLACE \n \\n code "${code}")
  string(REPLACE \r \\r code "${code}")
  string(REPLACE \" \\\\\" code "${code}") # double up
  string(REPLACE " " "\ " code "${code}")
  string(REPLACE \t \\t code "${code}")

  if(CMAKE_HOST_SYSTEM_NAME MATCHES "^Windows" AND NOT ARGS_WITHOUT_WINDOWS_POWERSHELL)
    set(${ARGS_OUT_VAR}
      "powershell" "-Command" "{ Start-Process ${CMAKE_COMMAND} -Wait -ArgumentList \"-P '${CMAKE_CURRENT_FUNCTION_LIST_FILE}' -- '${code}' }" PARENT_SCOPE)
  else()
    set(${ARGS_OUT_VAR}
      "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_FUNCTION_LIST_FILE}" -- "'${code}'" PARENT_SCOPE)
  endif()
endfunction()

