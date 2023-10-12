include_guard()

#[=======================================================================[.rst:

JcmMessages
-----------

#]=======================================================================]

include(JcmParseArguments)

# created custom command will parse this file in script mode to emit the message at build time
if(IN_SCRIPT_MODE)
  message(${ARGN})
  return()
endif()

#[=======================================================================[.rst:

jcm_create_message_command
^^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_create_message_command

  .. code-block:: cmake

    jcm_create_message_command(
      NAME <name>
      LEVEL <TRACE|DEBUG|VERBOSE|STATUS|NOTICE|AUTHOR_WARNING|WARNING|SEND_ERROR|FATAL_ERROR>
      MESSAGES <message>...)

Creates a custom command with the name specified by :cmake:variable:`NAME` that will emit all of
the messages provided to :cmake:variable:`MESSAGES` at the given log level, :cmake:variable:`LEVEL`.
This function and the generated command are used to easily report messages to the user from a
command with a specific log level. This differs from the `echo` cmake command (``cmake -E echo``)
because *echo* only emits messages to stdout without log levels. An alternative solution is to
generate a script file in the project's configuration and parse it within the command - that's what
this function encapsulates.

The command will parse this exact script file, :cmake:variable:`CMAKE_CURRENT_LIST_FILE`, to emit
the message, which may be a different file in the build tree and install tree. Nevertheless, since
:cmake:variable:`CMAKE_CURRENT_LIST_FILE` will be evaluated when :cmake:`jcm_create_message_command`
is invoked, this will point to the correct instance of `JcmMessages.cmake`.

Parameters
##########

One Value
~~~~~~~~~

:cmake:variable:`NAME`
  The name of the custom command to create by invoking this function.

:cmake:variable:`LEVEL`
  The log level of the messages emitted by the created command.

Multi Value
~~~~~~~~~~~

:cmake:variable:`MESSAGES`
  The string messages that will be emitted by the created command at the given log level.

Examples
########

.. code-block:: cmake

  if(MYLIB_SCHEMA_FILES_FOUND)
    add_custom_command(mylib_generate_sources
      COMMAND "command to actually generate sources")
  else()
    jcm_create_message_command(
      NAME mylib_generate_sources
      LEVEL FATAL_ERROR
      MESSAGES "Failed to generate sources with the given schema. Schema error ${err_message}")
  endif()

  # messages will only be emitted when target is built, not when project is configured
  add_custom_target(generate-sources COMMAND mylib_generate_sources)

#]=======================================================================]
function(jcm_create_message_command)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "NAME" "LEVEL"
    MULTI_VALUE_KEYWORDS "MESSAGES"
    REQUIRES_ALL "NAME" "LEVEL" "MESSAGES"
    ARGUMENTS "${ARGN}")

  set(acceptable_status "TRACE|DEBUG|VERBOSE|STATUS|NOTICE|AUTHOR_WARNING|WARNING|SEND_ERROR|FATAL_ERROR")
  if(NOT "${ARGS_LEVEL}" MATCHES "${acceptable_status}")
    message(FATAL_ERROR
      "Argument 'LEVEL' of ${CMAKE_CURRENT_FUNCTION} must be one of ${acceptable_status}")
  endif()

  add_custom_command(${ARGS_NAME}
    COMMAND "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_LIST_FILE}" "${ARGS_LEVEL}" "${MESSAGES}")
endfunction()
