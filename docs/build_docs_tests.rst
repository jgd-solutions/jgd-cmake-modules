Building Tests & Docs
---------------------

Building either of these targets first requires cloning the project sources:

Clone source code and enter the project root

.. code-block:: bash

  git clone https://github.com/jgd-solutions/jgd-cmake-modules.git
  cd jgd-cmake-modules


---------------------------------------------------------------------------------------


Building & Running Tests
========================

Enable Tests
~~~~~~~~~~~~

Automated tests are enabled with the option :cmake:variable:`JCM_ENABLE_TESTS` during CMake
configuration. The configure preset *tests-ninja* will do this.

.. code-block:: bash

  cmake -B <build-dir> -D JCM_ENABLE_TESTS=ON ... # manually
  cmake --preset tests-ninja                     # using preset

Run Tests
~~~~~~~~~

Since the project is all CMake code, there's nothing to build. We can go straight to running the
tests, where the subprojects will be internally built and tested as part of JCM's testing procedure.
Standard CTest commands will work, in addition to the test presets *tests* and *test-to-fail*.

.. code-block:: bash

  ctest --test-dir <build-dir> ... # manually
  ctest --preset test-to-fail      # using preset


---------------------------------------------------------------------------------------


Building Documentation
======================

Documentation is generated with `Sphinx <https://www.sphinx-doc.org/en/master/>`_, which is a
Python-based tool. In addition to the reStructuredText files within the project's `docs/` directory,
sections of code comments are annotated to contain reStructuredText, which will be fed to Sphinx and
contribute to the documentation (`modules.rst
<https://github.com/jgd-solutions/jgd-cmake-modules/blob/main/docs/modules.rst>`_).

Install Dependencies
~~~~~~~~~~~~~~~~~~~~

First, install the Python dependencies to preferrably a virtual environment - this includes Sphinx:

.. code-block:: bash

  python -m venv .venv                   # create virtual environment .venv
  source .venv/bin/activate              # activate virtual environment
  pip install -r sphinx-requirements.txt # install dependencies to virtual environment

Enable Docs
~~~~~~~~~~~

Documentation generation is enabled with the option :cmake:variable:`JCM_ENABLE_DOCS` during CMake
configuration.  The configure preset *docs-ninja* will do this. Ensure the virtual environment is
activated or JCM may not be able to find Sphinx.

.. code-block:: bash

  cmake -B <build-dir> -D JCM_ENABLE_DOCS=ON ... # manually
  cmake --preset docs-ninja                      # using preset

Build Docs
~~~~~~~~~~

Build the target *sphinx-docs* or use the preset *sphinx-docs* to invoke Sphinx, generating HTML
documentation in `<build-dir>/docs/sphinx`.

.. code-block:: bash

  cmake --build <build-dir> --target sphinx-docs # using target
  cmake --build --preset sphinx-docs             # using preset

View Docs
~~~~~~~~~

Open `<build-dir>/docs/sphinx/index.html` in your browser to view the documentation. Don't forget to
refresh the page between builds.
