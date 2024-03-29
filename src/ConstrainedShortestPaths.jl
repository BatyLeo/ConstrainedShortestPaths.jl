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

export basic_shortest_path, resource_shortest_path
export stochastic_routing_shortest_path, stochastic_routing_shortest_path_with_threshold
export generalized_constrained_shortest_path,
    generalized_constrained_shortest_path_with_threshold
export compute_bounds, generalized_a_star, generalized_a_star_with_threshold, CSPInstance
export remove_dominated!
export PiecewiseLinear, compose, intersection, meet

end
