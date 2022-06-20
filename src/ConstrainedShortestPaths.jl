module ConstrainedShortestPaths

using DataStructures
using Graphs
using SimpleTraits
using SparseArrays
using Statistics: mean
import Base: <=, minimum, +

export basic_shortest_path, resource_shortest_path
export stochastic_routing_shortest_path, stochastic_routing_shortest_path_with_threshold
export generalized_constrained_shortest_path, generalized_constrained_shortest_path_with_threshold
export compute_bounds, generalized_A_star, generalized_A_star_with_threshold, RCSPInstance
export remove_dominated!
export PiecewiseLinear, compose, intersection, meet

include("utils/utils.jl")
include("utils/piecewise_linear.jl")
include("algorithms.jl")
include("examples/basic_shortest_path.jl")
include("examples/resource_shortest_path.jl")
include("examples/stochastic_routing.jl")

end
