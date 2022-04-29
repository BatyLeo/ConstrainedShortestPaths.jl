# # Build a custom wrapper

# !!! warning "Work in progress"

using ConstrainedShortestPaths
using Graphs, SparseArrays
import Base: <=, minimum

# ## Resources

struct Resource
    c::Float64
    w::Float64
end

#

function <=(r1::Resource, r2::Resource)
    return r1.c <= r2.c && r1.w <= r2.w
end

function minimum(R::Vector{Resource})
    return Resource(minimum(r.c for r in R), minimum(r.w for r in R))
end

# ## Expansion functions

struct ExpansionFunction
    c::Float64
    w::Float64
end

function (f::ExpansionFunction)(q::Resource)
    return Resource(f.c + q.c, f.w + q.w)
end


# ## Cost function

struct Cost
    W::Float64
end

function (cost::Cost)(fr::Resource, br::Resource)
    return fr.w + br.w <= cost.W ? fr.c + br.c : Inf
end

# ## Test

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

cost_list = [[0.], [0.], [10.], [0.], [0]]
w = [0. for i in 1:nb_vertices, j in 1:nb_vertices, k in 1:1]
for ((i, j), k) in zip(edge_list, cost_list)
    w[i, j, :] = k
end

## origin forward resource and backward forward resource set to 0
resource = Resource(0., 0.)

## forward and backward expansion functions are equal
If = [src(e) for e in edges(graph)]
Jf = [dst(e) for e in edges(graph)]
f = [ExpansionFunction(d[i, j], w[i, j]) for (i, j) in zip(If, Jf)]
F = sparse(If, Jf, f);

instance = RCSPInstance(graph, resource, resource, Cost(W), F, F)
p_star, c_star = generalized_constrained_shortest_path(instance)
