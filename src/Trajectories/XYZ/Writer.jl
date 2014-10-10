#===============================================================================
         Implementation of the XYZ trajectories Writer

    XYZ format is a text-based format, with atomic informations arranged as:
            <name> <x> <y> <z> [<vx> <vy> <vz>]
    The two first lines of each frame contains a comment header, and the number
    of atoms.
===============================================================================#

type XYZWriter <: AbstractWriterIO
    file::IOStream
    header::String
end


function XYZWriter(filename::String; header="Generated by MolecularAnalysis.jl")
    file = open(filename, "w")
    return XYZWriter(file, header)
end


function write(traj::Writer{XYZWriter}, frame::Frame)
    header = traj.writer.header * " Step = " * string(frame.step) * "\n"
    natoms = string(size(frame)) * "\n"
    write(traj.writer.file, header)
    write(traj.writer.file, natoms)
    write_xyz_data(traj.writer.file, frame)
end

function write(file::Writer{XYZWriter}, frames::Vector{Frame})
    for frame in frames
       write(file, frame)
    end
end

function write_xyz_data(file::IO, frame::Frame; velocities=false)
   for i=1:size(frame)
      line = frame.topology.atoms[i].name * " "
      line *= string(frame.positions[i][1]) * " "
      line *= string(frame.positions[i][2]) * " "
      line *= string(frame.positions[i][3])
      if velocities
          line *=  " " * string(frame.velocities[i][1]) * " "
          line *= string(frame.velocities[i][2]) * " "
          line *= string(frame.velocities[i][3])
      end
      line *= "\n"
      write(file, line)
   end
end
