# Copyright (c) Guillaume Fraux 2014
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# ============================================================================ #
#                       Topologie read and write
# ============================================================================ #

export read_topology

include("Topologies/XYZ.jl")
include("Topologies/LAMMPS.jl")

function read_topology(filename)
    extension = split(strip(filename), ".")[end]
    if extension == "xyz"
        info("Reading topology in XYZ format")
        return read_xyz_topology(filename)
    elseif extension == "lmp"
        info("Reading topology in LAMMPS format")
        return read_lmp_topology(filename)
    else
        error("The '$extension' extension is not recognized")
    end
end

import Jumos: Topology
Topology(filename::String) = read_topology(filename)
