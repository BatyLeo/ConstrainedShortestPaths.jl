```@meta
EditURL = "literate/custom.jl"
```

# Implement a custom problem

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

````@example custom
using ConstrainedShortestPaths
using Graphs, SparseArrays
import Base: <=, minimum
````

## Resources

Forward and backward resources for this example are in the same space:

````@example custom
struct Resource
    c::Float64
    w::Float64
end
````

`Base.<=` and `Base.minimum`

````@example custom
function <=(r1::Resource, r2::Resource)
    return r1.c <= r2.c && r1.w <= r2.w
end

function minimum(R::Vector{Resource})
    return Resource(minimum(r.c for r in R), minimum(r.w for r in R))
end
````

## Expansion functions

Same as the resources, the forward and backward expansion functions coincide in this example.

````@example custom
struct ExpansionFunction
    c::Float64
    w::Float64
end

function (f::ExpansionFunction)(q::Resource)
    return Resource(f.c + q.c, f.w + q.w)
end
````

## Cost function

````@example custom
struct Cost
    W::Float64
end

function (cost::Cost)(fr::Resource, br::Resource)
    return fr.w + br.w <= cost.W ? fr.c + br.c : Inf
end
````

## Test on an instance

````@example custom
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

# origin forward resource and backward forward resource set to 0
resource = Resource(0.0, 0.0)

# forward and backward expansion functions are equal
If = [src(e) for e in edges(graph)]
Jf = [dst(e) for e in edges(graph)]
f = [ExpansionFunction(d[i, j], w[i, j]) for (i, j) in zip(If, Jf)]
F = sparse(If, Jf, f);

instance = CSPInstance(graph, 1, nb_vertices, resource, resource, Cost(W), F, F)
(; p_star, c_star) = generalized_constrained_shortest_path(instance)
@info "Result" c_star p_star
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

