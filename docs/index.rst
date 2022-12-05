.. jgd-cmake-modules documentation master file

Welcome to JCM's documentation!
===============================

jgd-cmake-modules
-----------------

A set of CMake modules to easily and consistently develop proper CMake based projects conforming to
the `Canonical Project Structure`_.

Pages
-----

.. toctree::
   :maxdepth: 2

   getting_started
   overview
   find_modules
   modules
   tests_readme_link
   build_with_cmake


Indices
-------

* :ref:`genindex`
* :ref:`search`


Sample
------

   .. literalinclude:: ../tests/libsingle/CMakeLists.txt
      :language: cmake
      :caption: CMakeLists.txt

   .. literalinclude:: ../tests/libsingle/libsingle/CMakeLists.txt
      :language: cmake
      :caption: libsingle/CMakeLists.txt

   .. literalinclude:: ../tests/libsingle/tests/CMakeLists.txt
      :language: cmake
      :caption: tests/CMakeLists.txt

   .. literalinclude:: ../tests/libsingle/docs/CMakeLists.txt
      :language: cmake
      :caption: docs/CMakeLists.txt

Examples
--------

This project uses its own modules, and acts as its own example!

Additionally, the `tests/ <https://github.com/jgd-solutions/jgd-cmake-modules/tree/main/tests>`_ directory has sample projects that use *jgd-cmake-modules*.  Each project
acts as an example of using *jgd-cmake-modules* and the `Canonical Project Structure`_.
