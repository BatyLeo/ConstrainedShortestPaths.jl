```@meta
EditURL = "literate/resource_shortest_path.jl"
```

# Shortest path with linear resource constraints

In this tutorial we want to solve the following resource constrained shortest path:
```math
\begin{aligned}
\min_{p\in \mathcal{P_{od}}} & \sum_{a\in p} c_a & \\
s.t. & \sum_{a\in p} w_a^k \leq W^k, & \forall k \in [K]
\end{aligned}
```

````@example resource_shortest_path
using ConstrainedShortestPaths
using Graphs, SparseArrays
using GLMakie, GraphMakie
````

Let's create a simple graph:

````@example resource_shortest_path
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
````

We now add resource costs ``w_a`` on edges,
and a resource constraint of the form: ``\sum\limits_{a\in P} w_a \leq W``

````@example resource_shortest_path
W = [1.0]
cost_list = [[0], [0], [10], [0], [0]]
w = [0.0 for i in 1:nb_vertices, j in 1:nb_vertices, k in 1:1]
for ((i, j), c) in zip(edge_list, cost_list)
    w[i, j, :] = c
end

graphplot(
    graph;
    node_color=:red,
    nlabels=["$i" for i in 1:nb_vertices],
    elabels=["d=$(d[e.src, e.dst]), w=$(w[e.src, e.dst, :])" for e in edges(graph)],
)
````

With these costs, the optimal path should be [1, 2, 4], with length 2.

````@example resource_shortest_path
p_star, c_star = resource_shortest_path(graph, 1, nb_vertices, W, d, w)
@info "Solution found" p_star c_star
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

