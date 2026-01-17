.. jgd-cmake-modules documentation master file

JGD CMake Modules documentation
===============================

.. image:: ../data/logo.png
   :width: 30%
   :align: center

Library of CMake modules to easily and consistently develop proper CMake projects.


Pages
-----

.. toctree::
   :maxdepth: 2

   getting_started
   overview
   find_modules
   modules
   build_docs_tests
   tests_readme_link
   cmake_command_tutorial


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

   .. literalinclude:: ../tests/libsingle/libsingle/material/CMakeLists.txt
      :language: cmake
      :caption: libsingle/material/CMakeLists.txt

   .. literalinclude:: ../tests/libsingle/tests/CMakeLists.txt
      :language: cmake
      :caption: tests/CMakeLists.txt

   .. literalinclude:: ../tests/libsingle/docs/CMakeLists.txt
      :language: cmake
      :caption: docs/CMakeLists.txt

   .. literalinclude:: ../tests/libsingle/cmake/libsingle-config.cmake.in
      :language: none
      :caption: cmake/libsingle-config.cmake.in

Examples
--------

This project uses its own modules, and acts as its own example!

Additionally, the `tests/ <https://github.com/jgd-solutions/jgd-cmake-modules/tree/main/tests>`_ directory has sample projects that use *jgd-cmake-modules*.  Each project
acts as an example of using *jgd-cmake-modules* and the `Canonical Project Structure`_.
