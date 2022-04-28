module ConstrainedShortestPaths

using Graphs
using SimpleTraits
using SparseArrays
using DataStructures
import Base: <=, minimum

export basic_shortest_path, resource_shortest_path
export generalized_constrained_shortest_path
export RCSPInstance, remove_dominated!
export PiecewiseLinear, compose, intersection, meet

include("utils.jl")
include("instance.jl")
include("algorithms.jl")
include("examples/basic_shortest_path.jl")
include("examples/resource_shortest_path.jl")
include("examples/stochastic_routing.jl")
include("examples/piecewise_linear.jl")

end
