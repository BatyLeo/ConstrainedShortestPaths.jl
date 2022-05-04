```@meta
EditURL = "<unknown>/test/tutorial.jl"
```

# Basic usage

At the moment, this library provides wrappers for two problems: the usual shortest path and
resource constrained shortest path.

````@example tutorial
# Import relevant packages
using ConstrainedShortestPaths
using Graphs, SparseArrays
using Plots, GraphRecipes
````

Let's create a simple graph in order to test our wrappers:

````@example tutorial
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
graphplot(
    graph,
    x=[0, 1, 1, 2], y=[0, 1, -1, 0], curves=false,
    nodecolor=:green, nodesize=0.3,
    nodeshape=:circle, linewidth=3,
    names=1:nb_vertices, fontsize=15,
    edgelabel=d,
)
````

## Usual shortest path

The usual shortest path on our `graph` is (1, 2, 3, 4), with length 1.

````@example tutorial
p_star, c_star = basic_shortest_path(graph, d)
@info "Solution found" p_star c_star
````

Note: for the usual shortest path, it's probably better to use directly one of the
shortest paths algorithms from [Graphs.jl](https://juliagraphs.org/Graphs.jl/dev/algorithms/shortestpaths/#Shortest-paths)

## Resource constrained shortest path

We now add resource costs ``w_a`` on edges,
and a resource constraint of the form: ``\sum\limits_{a\in P} w_a \leq W``

````@example tutorial
W = [1.0]

cost_list = [[0.], [0.], [10.], [0.], [0]]
w = [0. for i in 1:nb_vertices, j in 1:nb_vertices, k in 1:1]
for ((i, j), k) in zip(edge_list, cost_list)
    w[i, j, :] = k
end
````

With these costs, the optimal path should be [1, 2, 4], with length 2.

````@example tutorial
p_star, c_star = resource_shortest_path(graph, W, d, w)
@info "Solution found" p_star c_star
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

