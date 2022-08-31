#[=======================================================================[.rst:
CMakeDependentOption
--------------------

Macro to provide an option dependent on other options.

This macro presents an option to the user only if a set of other
conditions are true.

.. command:: cmake_dependent_option

  .. code-block:: cmake

    cmake_dependent_option(<option> "<help_text>" <value> <depends> <force>)

  Makes ``<option>`` available to the user if the
  :ref:`semicolon-separated list <CMake Language Lists>` of conditions in
  ``<depends>`` are all true.  Otherwise, a local variable named ``<option>``
  is set to ``<force>``.

  When ``<option>`` is available, the given ``<help_text>`` and initial
  ``<value>`` are used. Otherwise, any value set by the user is preserved for
  when ``<depends>`` is satisfied in the future.

  Note that the ``<option>`` variable only has a value which satisfies the
  ``<depends>`` condition within the scope of the caller because it is a local
  variable.

Example invocation:

.. code-block:: cmake

  cmake_dependent_option(USE_FOO "Use Foo" ON "USE_BAR;NOT USE_ZOT" OFF)

If ``USE_BAR`` is true and ``USE_ZOT`` is false, this provides an option called
``USE_FOO`` that defaults to ON. Otherwise, it sets ``USE_FOO`` to OFF and
hides the option from the user. If the status of ``USE_BAR`` or ``USE_ZOT``
ever changes, any value for the ``USE_FOO`` option is saved so that when the
option is re-enabled it retains its old value.

.. versionadded:: 3.22

  Full :ref:`Condition Syntax` is now supported.  See policy :policy:`CMP0127`.

#]=======================================================================]
