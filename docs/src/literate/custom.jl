# # Implement a custom problem

#=
In this tutorial, you will learn how to use this package to solve your own custom
constrained shortest path problem.

First of all, make sure you read the [Mathematical background](@ref). In order to use the
[`generalized_constrained_shortest_path`](@ref) on your custom problem, you need to
define a few different types and methods:
- Types that need to be implemented:
    - Resources types (backward and forward)
    - Expansion functions (backward and forward)
- Methods that need to be implemented:
    - `Base.<=` between two forward resources
    - `Base.minimum` of a vector of backward resources
    - Make forward functions callable on forward resources
    - Make backward function callable on backward resources
    - A callable cost function

You can checkout examples already implemented in the [`src/examples`](https://github.com/BatyLeo/ConstrainedShortestPaths.jl/tree/main/src/examples)
folder of this package.

## Example on the unidimensional resource shortest path

We illustrate this on the same problem a in [Shortest path with linear resource constraints](@ref)
but simplified with only one constraint.

=#

using ConstrainedShortestPaths
using Graphs, SparseArrays

#=
## Resources

Forward and backward resources for this example are in the same space:
=#
struct Resource
    c::Float64
    w::Float64
end

# `Base.<=` and `Base.minimum`

function Base.:<=(r1::Resource, r2::Resource)
    return r1.c <= r2.c && r1.w <= r2.w
end

function Base.min(r₁::Resource, r₂::Resource)
    new_c = min(r₁.c, r₂.c)
    new_w = min(r₁.w, r₂.w)
    return Resource(new_c, new_w)
end

#=
## Expansion functions

=#

struct ForwardExpansionFunction
    c::Float64
    w::Float64
end

function (f::ForwardExpansionFunction)(q::Resource; W)
    return Resource(f.c + q.c, f.w + q.w), f.w + q.w <= W
end

struct BackwardExpansionFunction
    c::Float64
    w::Float64
end

function (f::BackwardExpansionFunction)(q::Resource; W)
    return Resource(f.c + q.c, f.w + q.w)
end

# ## Cost function

struct Cost end

function (cost::Cost)(fr::Resource, br::Resource)
    return fr.c + br.c
end

# ## Test on an instance

nb_vertices = 4
graph = SimpleDiGraph(nb_vertices)
edge_list = [(1, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
distance_list = [1, 2, -1, 1, 1]
for (i, j) in edge_list
    add_edge!(graph, i, j)
end
I = [src(e) for e in edges(graph)]
J = [dst(e) for e in edges(graph)]
d = sparse(I, J, distance_list)

W = 1.0

cost_list = [[0.0], [0.0], [10.0], [0.0], [0]]
w = [0.0 for i in 1:nb_vertices, j in 1:nb_vertices, k in 1:1]
for ((i, j), k) in zip(edge_list, cost_list)
    w[i, j, :] = k
end

## origin forward resource and backward forward resource set to 0
resource = Resource(0.0, 0.0)

## forward and backward expansion functions are equal
If = [src(e) for e in edges(graph)]
Jf = [dst(e) for e in edges(graph)]
ff = [ForwardExpansionFunction(d[i, j], w[i, j]) for (i, j) in zip(If, Jf)]
fb = [BackwardExpansionFunction(d[i, j], w[i, j]) for (i, j) in zip(If, Jf)]
FF = sparse(If, Jf, ff);
FB = sparse(If, Jf, fb);

instance = CSPInstance(;
    graph,
    origin_vertex=1,
    destination_vertex=nb_vertices,
    origin_forward_resource=resource,
    destination_backward_resource=resource,
    cost_function=Cost(),
    forward_functions=FF,
    backward_functions=FB,
)
(; p_star, c_star) = generalized_constrained_shortest_path(instance; W=W)
@info "Result" c_star p_star
