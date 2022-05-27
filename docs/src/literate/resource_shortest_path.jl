# # Shortest path with linear resource constraints

#=
o-d path, K resources
```math
\boxed{\begin{aligned}
\min_{p\in \mathcal{P_{od}}} & \sum_{a\in p} d_a & \\
s.t. & \sum_{a\in p} w_a^k \leq W^k, & \forall k \in [K]
\end{aligned}}
```
=#

using ConstrainedShortestPaths
using Graphs, SparseArrays
using GLMakie, GraphMakie

# Let's create a simple graph in order to test our wrappers:

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

#=
We now add resource costs ``w_a`` on edges,
and a resource constraint of the form: ``\sum\limits_{a\in P} w_a \leq W``
=#

W = [1.]
cost_list = [[0], [0], [10], [0], [0]]
w = [0. for i in 1:nb_vertices, j in 1:nb_vertices, k in 1:1]
for ((i, j), c) in zip(edge_list, cost_list)
    w[i, j, :] = c
end

graphplot(graph;
    node_color=:red,
    nlabels=["$i" for i in 1:nb_vertices],
    elabels=["d=$(d[e.src, e.dst]), w=$(w[e.src, e.dst, :])" for e in edges(graph)]
)

# With these costs, the optimal path should be [1, 2, 4], with length 2.
p_star, c_star = resource_shortest_path(graph, W, d, w)
@info "Solution found" p_star c_star
