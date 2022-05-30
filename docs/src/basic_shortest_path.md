```@meta
EditURL = "<unknown>/docs/src/literate/basic_shortest_path.jl"
```

# Usual shortest path

In this first tutorial, we will use the [`basic_shortest_path`](@ref) method to solve
the usual shortest path problem (no constraints and linear cost) :
```math
\min_{P\in \mathcal{P_{od}}} \sum_{a\in P} c_a
```

!!! note
    This example is mainly for tutorial purposes. You probably will achieve better
    performance by using  directly one of the shortest paths algorithms from
    [Graphs.jl](https://juliagraphs.org/Graphs.jl/dev/algorithms/shortestpaths/#Shortest-paths)
    or implementing your own Dijkstra/dynamic programming algorithm.

Let's import the package, and fix the seed for reproducibility.

````@example basic_shortest_path
using ConstrainedShortestPaths
using Random

Random.seed!(67)
include("utils.jl"); # imports random_acyclic_digraph
nothing #hide
````

We wreate a random acyclic directed graph

````@example basic_shortest_path
nb_vertices = 50
g = random_acyclic_digraph(nb_vertices)
````

The adjacency matrix is triangular

````@example basic_shortest_path
adjacency_matrix(g)
````

Create a cost matrix with random values

````@example basic_shortest_path
using SparseArrays
distance_list = [rand() * 20 - 5 for _ in 1:ne(g)]
I = [src(e) for e in edges(g)]
J = [dst(e) for e in edges(g)]
cost_matrix = sparse(I, J, distance_list);
nothing #hide
````

Compute the shortest path

````@example basic_shortest_path
p_star, c_star = basic_shortest_path(g, cost_matrix)
@info "Solution found" c_star p_star'
````

We can check that we obtain the same results with the dynamic programming algorithm from Graphs.jl

````@example basic_shortest_path
p = enumerate_paths(bellman_ford_shortest_paths(g, 1, cost_matrix), nb_vertices)
c = sum(cost_matrix[p[i], p[i+1]] for i in eachindex(p[1:end-1]))
@info "Bellman" c p'
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

