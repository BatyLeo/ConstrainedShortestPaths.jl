module ConstrainedShortestPaths

using DataStructures
using Graphs
using SimpleTraits
using SparseArrays
using Statistics: mean
import Base: <=, minimum, +

include("utils/utils.jl")
include("utils/piecewise_linear.jl")
include("algorithms.jl")
include("examples/basic_shortest_path.jl")
include("examples/resource_shortest_path.jl")
include("examples/stochastic_routing.jl")

export basic_shortest_path, resource_shortest_path, stochastic_routing_shortest_path
export generalized_constrained_shortest_path, compute_bounds, generalized_A_star, CSPInstance
export remove_dominated!
export PiecewiseLinear, compose, intersection, meet
export topological_order

end
