module ConstrainedShortestPaths

using SimpleTraits
using Graphs
using DataStructures
import Base: <=, minimum
using SparseArrays

include("utils.jl")
include("instance.jl")
include("algorithms.jl")
include("examples/basic_shortest_path.jl")
include("examples/resource_shortest_path.jl")

export basic_shortest_path, resource_shortest_path
export generalized_constrained_shortest_path
export RCSPInstance, remove_dominated!

end
