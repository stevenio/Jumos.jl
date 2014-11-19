#===============================================================================
                    Molecular dynamic simulations
===============================================================================#
import Base: show
export Simulation, MDSimulation, run!

Array3D = Vector{Vect3D{Float32}}

abstract Simulation

include("MD/potentials.jl")

typealias Interactions Dict{(Integer, Integer), Potential}

include("MD/forces.jl")
include("MD/integrators.jl")

include("MD/enforce.jl")
include("MD/check.jl")
abstract BaseCompute
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
    # Algorithms
    interactions    :: Interactions
    forces_computer :: BaseForcesComputer
    integrator      :: BaseIntegrator
    enforces        :: Vector{BaseEnforce}
    checks          :: Vector{BaseCheck}
    computes        :: Vector{BaseCompute}
    outputs         :: Vector{BaseOutput}
    # Data
    topology        :: Topology
    box             :: SimBox
    frame           :: Frame
    masses          :: Vector{Float64}
    forces          :: Array3D
    # all other data to be shared
    data            :: Dict{Symbol, Any}
end

# This define the default values for a simulation !
function MDSimulation(integrator=VelocityVerlet(1.0))
    interactions = Interactions()
    forces_computer = NaiveForces()

    enforces = BaseEnforce[]
    checks = BaseCheck[]
    computes = BaseCompute[]
    outputs = BaseOutput[]

    topology = Topology()
    box = SimBox()
    masses = Float64[]
    forces = Array3D[]
    frame = Frame(topology)
    data = Dict(:frame => frame)

    return MDSimulation(interactions,
                        forces_computer,
                        integrator,
                        enforces,
                        checks,
                        computes,
                        outputs,
                        topology,
                        box,
                        frame,
                        masses,
                        forces,
                        data
                        )
end

# Convenient method.
MDSimulation(timestep::Real) = MDSimulation(VelocityVerlet(timestep))

include("MD/compute.jl")
include("MD/initial_velocities.jl")

# Run a Molecular Dynamics simulation for nsteps steps
function run!(sim::MDSimulation, nsteps::Integer)

    sim.masses = atomic_masses(sim.topology)

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
    check_masses(sim)
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
    ntypes = size(sim.topology)
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

function check_masses(sim::MDSimulation)
    if countnz(sim.masses) != size(sim.topology)
        bad_masses = Set()
        for (i, val) in enumerate(sim.masses)
            if val == 0.0
                union!(bad_masses, [sim.topology[i].name])
            end
        end
        missing = join(bad_masses, " ")
        throw(SimulationConfigurationError(
                "Missing masses for the following atomic types: $missing"
            ))
    end
end

# Compute forces between atoms at a given step
function get_forces(sim::MDSimulation)
    sim.forces_computer(sim.forces, sim.frame, sim.interactions)
end

# Integrate the equations of motion
function integrate(sim::MDSimulation)
    sim.integrator(sim.frame, sim.forces)
end

# Enforce a value like temperature or presure or volume, …
function enforce(sim::MDSimulation)
    for callback in sim.enforces
        callback(sim.frame)
    end
end

# Check the physical consistency of the simulation : number of particles is
# constant, global velocity is zero, …
function check(sim::MDSimulation)
    for callback in sim.checks
        callback(sim.frame)
    end
end


# Compute values of interest : temperature, total energy, radial distribution
# functions, diffusion coefficients, …
function compute(sim::MDSimulation)
    for callback in sim.computes
        callback(sim)
    end
end

# Output data to files : trajectories, energy as function of time, …
function output(sim::MDSimulation)
    context = sim.data
    for out in sim.outputs
        write(out, context)
    end
end

include("UI.jl")
