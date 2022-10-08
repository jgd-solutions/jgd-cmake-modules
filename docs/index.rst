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

.. figure:: data/top_level_sample.svg
   :width: 60%
   :align: center
   :alt: Sample code of top-level cmake with jgd-cmake-modules

   CMakeLists.txt

.. figure:: data/subdirectory_sample.svg
   :width: 60%
   :align: center
   :alt: Sample code of subdirectory cmake with jgd-cmake-modules

   libsample/CMakeLists.txt


Examples
--------

This project uses its own modules, and acts as its own example!

Additionally, the `tests/ <https://github.com/jgd-solutions/jgd-cmake-modules/tree/main/tests>`_ directory has sample projects that use *jgd-cmake-modules*.  Each project
acts as an example of using *jgd-cmake-modules* and the `Canonical Project Structure`_.
