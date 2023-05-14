include_guard()

#[=======================================================================[.rst:

JcmMessages
-----------

#]=======================================================================]

include(JcmParseArguments)

if(IN_SCRIPT_MODE)
  message(${ARGN})
  return()
endif()

function(jcm_create_message_command)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "NAME" "LEVEL"
    MULTI_VALUE_KEYWORDS "MESSAGES"
    REQUIRES_ALL "NAME" "LEVEL" "MESSAGES"
    ARGUMENTS "${ARGN}")

  set(acceptable_status "STATUS|NOTICE|WARNING|FATAL_ERROR")
  if(NOT "${ARGS_LEVEL}" MATCHES "${acceptable_status}")
    message(FATAL_ERROR
      "Argument 'LEVEL' of ${CMAKE_CURRENT_FUNCTION} must be one of ${acceptable_status}")
  endif()

  add_custom_command(${ARGS_NAME}
    COMMAND "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_LIST_FILE}" "${ARGS_LEVEL}" "${MESSAGES}")
endfunction()
