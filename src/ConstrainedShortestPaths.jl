module ConstrainedShortestPaths

using DataStructures: PriorityQueue, enqueue!, dequeue!, isempty
using DocStringExtensions: TYPEDEF, TYPEDFIELDS, TYPEDSIGNATURES
using Graphs:
    AbstractGraph,
    is_directed,
    is_cyclic,
    nv,
    weights,
    src,
    dst,
    edges,
    outneighbors,
    inneighbors,
    induced_subgraph
using PiecewiseLinearFunctions:
    PiecewiseLinearFunction, convex_meet, remove_redundant_breakpoints, convex_meet
using SparseArrays: sparse
using Statistics: mean

include("utils/utils.jl")
include("interface.jl")
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

end
