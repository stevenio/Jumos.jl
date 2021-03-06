# Copyright (c) Guillaume Fraux 2014
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# ============================================================================ #
#                  Useful types for topology storage.
# ============================================================================ #

import Base: size, show, getindex, setindex!

export Topology, Bond, Angle, Dihedral
export atomic_masses, get_id_from_name, dummy_topology

typealias Bond (Int, Int)
typealias Angle (Int, Int, Int)
typealias Dihedral (Int, Int, Int, Int)


type Topology
    atom_types::Vector{Atom}
    atoms::Vector{Int}
    molecules::Dict{String, Array{Int,1}}
    residues::Dict{String, Array{Int,1}}
    bonds::Vector{Bond}
    angles::Vector{Angle}
    dihedrals::Vector{Dihedral}  # Reals dihedrals
    impropers::Vector{Dihedral}  # Impropers dihedrals
end

Topology(natoms::Integer) = Topology(Atom[],
                                     Array(Int64, natoms),
                                     Dict(),
                                     Dict(),
                                     Bond[],
                                     Angle[],
                                     Dihedral[],
                                     Dihedral[]
                                    )
Topology() = Topology(0)

function dummy_topology(natoms::Integer)
    topology = Topology(natoms)
    push!(topology.atom_types, Atom("Dummy"))
    fill!(topology.atoms, 1)
    return topology
end

function size(a::Dict{String, Array{Int64,1}})
    # Just count the number of dict entry
    i = 0
    for (k, v) in a
        i += 1
    end
    return i
end

size(topology::Topology) = size(topology.atoms, 1)

function show(io::IO, top::Topology)
    n_atoms = size(top.atoms, 1)
    n_molecules = size(top.molecules)
    n_residues = size(top.residues)
    n_bonds = size(top.bonds, 1)
    n_angles = size(top.angles, 1)
    n_dihedrals = size(top.dihedrals, 1)
    show(io, "Topology with $n_atoms atoms, $n_molecules molecules, " *
             "$n_residues residues, $n_bonds bonds, $n_angles angles, " *
             "$n_dihedrals dihedrals.")
end

function getindex(topology::Topology, i::Integer)
    atom_type = topology.atoms[i]
    return topology.atom_types[atom_type]
end

function setindex!(topology::Topology, atom::Atom, idx::Integer)
    atom_type = 0
    for (i, a) in enumerate(topology.atom_types)
        if atom == a
            atom_type = i
        end
    end

    # The atom type is not already defined
    if atom_type == 0
        push!(topology.atom_types, atom)
        atom_type = size(topology.atom_types, 1)
    end

    topology.atoms[idx] = atom_type
end

function get_id_from_name(topology::Topology, name::String)
    # Return the first match. TODO: check for atomic names unicity
    for (idx, atom_type) in enumerate(topology.atom_types)
        if atom_type.name == name
            return idx
        end
    end
    throw(KeyError())
end

function atomic_masses(topology::Topology)
    masses = zeros(Float64, size(topology))
    @inbounds for i=1:size(topology)
        atom = topology[i]
        if atom.mass == 0.0
            atom.mass = get_mass(atom)
        end
        masses[i] = atom.mass
    end
    return masses
end
