jgd-cmake-modules
=================

A set of CMake modules to easily and consistently develop proper CMake based projects.
For a short overview of the project, see `Overview <docs/overview>`_.

Sample
------

.. figure:: data/images/top_level_sample.svg
   :width: 60%
   :align: center
   :alt: Sample code of top-level cmake with jgd-cmake-modules

   libsample/CMakeLists.txt

.. figure:: data/images/subdirectory_sample.svg
   :align: center
   :alt: Sample code of subdirectory cmake with jgd-cmake-modules

   libsample/libsample/CMakeLists.txt

Examples
--------

This project uses its own modules, and acts as its own example!

Additionally, the `tests/` directory has sample projects that use *jgd-cmake-modules*. These projects are
configured and built as part of *jgd-cmake-modules*'s automated tests. Each project also acts as an
example of using
*jgd-cmake-modules* and the `Canonical Project Structure <https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2018/p1204r0.html#:~:text=The%20canonical%20structure%20is%20primarily,specific%20and%20well%2Ddefined%20function.>`_.
See `tests/README.rst <tests/README.rst>`_ for more information.
