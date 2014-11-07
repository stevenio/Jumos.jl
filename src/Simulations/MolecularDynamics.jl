#===============================================================================
                    Molecular dynamic simulations
===============================================================================#
import Base: show
export Simulation, MDSimulation, run!

abstract Simulation

include("MD/potentials.jl")

typealias Interaction Dict{(Integer, Integer), Potential}

include("MD/forces.jl")
include("MD/integrators.jl")

include("MD/enforce.jl")
include("MD/check.jl")
include("MD/compute.jl")
include("MD/output.jl")

type SimulationConfigurationError <: Exception
    msg :: String
end
export SimulationConfigurationError

function show(io::IO, e::SimulationConfigurationError)
    print(io, "Simulation Configuration Error : \n")
    print(io, e.msg)
end

type MDSimulation <: Simulation
    interactions    :: Vector{Interaction}
    forces_computer :: BaseForcesComputer
    integrator      :: BaseIntegrator
    enforces        :: Vector{BaseEnforce}
    checks          :: Vector{BaseCheck}
    computes        :: Vector{BaseCompute}
    outputs         :: Vector{BaseOutput}
    data            :: Frame
end

# Run a Molecular Dynamics simulation for nsteps steps
function run!(sim::MDSimulation, nsteps::Integer)

    check_settings(sim)

    for i=1:nsteps
        get_forces(sim)
        integrate(sim)
        enforce(sim)
        check(sim)
        compute(sim)
        output(sim)
    end
    return nothing
end

# Check that everything is effectivelly defined by the user
function check_settings(sim::MDSimulation)
    check_interactions(sim)
end

function check_interactions(sim::MDSimulation)
    atomic_pairs = Set{(Integer, Integer)}()
    for (i, j, potential) in sim.interactions
        union!(atomic_pairs, (i, j))
        if potential ∉ sim.potentials
            warn("Adding the potential $(potential.potential) to the simulation")
            push!(sim.potentials, potential)
        end
    end

    all_atomic_pairs = IntSet()
    const ntypes = size(sim.data.topology)
    for i=1:ntypes, j=1:ntypes
        union!(all_atomic_pairs, [(i, j), (j, i)])
    end
    setdiff!(all_atomic_pairs, atomic_pairs)
    if size(all_atomic_pairs) != 0
        missings = ""
        for (i, j) in all_atomic_pairs
            missings *= string(sim.atoms[i].name) * " - " * string(sim.atoms[j].name) * "\n"
        end
        throw(SimulationConfigurationError(
            "The following atom pairs do not have any interaction:

            $missings
            "
        ))
    end
end

# Compute forces between atoms at a given step
function get_forces(sim::MDSimulation)
    sim.data.forces = sim.forces_computer(sim.data, sim.interactions)
end

# Integrate the equations of motion
function integrate(sim::MDSimulation)
    sim.integrator(sim.data)
end

# Enforce a value like temperature or presure or volume, …
function enforce(sim::MDSimulation)
    for callback in sim.enforces
        callback(sim.data)
    end
end

# Check the physical consistency of the simulation : number of particles is
# constant, global velocity is zero, …
function check(sim::MDSimulation)
    for callback in sim.checks
        callback(sim.data)
    end
end


# Compute values of interest : temperature, total energy, radial distribution
# functions, diffusion coefficients, …
function compute(sim::MDSimulation)
    for callback in sim.computes
        callback(sim.data)
    end
end

#TODO: find a way to link a compute and an output. A semi-global dict maybe ?

# Output data to files : trajectories, energy as function of time, …
function output(sim::MDSimulation)
    context = sim.data
    for out in sim.outputs
        write(out, context)
    end
end

include("UI.jl")