Welcome to Jumos's documentation!
=================================

`Jumos` is a package for molecular simulations using the
`Julia <http://julialang.org/>`_ language. It aims at being as flexible as
possible, and allowing the easy use and development of novel algorithm for
each part of a simulation. Every algorithm, from potential computation, long
range interactions, pair lists computing, outputs, `etc.` can be customised.

Jumos also includes code for trajectory analysis, either during the simulation
run or by reading frames in a file.

.. warning::
    This package is in a very alpha stage, and still in heavy developement.
    Breaking changes can occurs in the API without any notice at any time.

This documentation is divided in two parts: first come the user manual, starting
by some explanation about usal :ref:`algorithms in simulations <simulation-steps>`
and an :ref:`example <simulation-usage>` of how we can use `Jumos` to run a
molecular dynamic simulation. The second part is the developer documentation,
exposing the internal of `Jumos`, and how we can use them to programm new
algorithms.

Installation
------------

To install `Jumos`, simply run ``Pkg.add("Jumos")`` at julia prompt. You may
also want to run ``Pkg.test("Jumos")`` to run the tests.

Only julia 0.4 prerelease version is supported, because `Jumos` makes use of
a lot of features from the 0.4 version.

User manual
-----------

.. toctree::
    :maxdepth: 2

    simulations/index
    trajectories
    analysis/index
    units

Developer documentation
-----------------------

.. toctree::
    :maxdepth: 2

    dev/index
