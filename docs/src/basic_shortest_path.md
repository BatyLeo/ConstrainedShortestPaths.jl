```@meta
EditURL = "<unknown>/docs/src/literate/basic_shortest_path.jl"
```

# Usual shortest path

o-d path, K resources
```math
\boxed{\min_{p\in \mathcal{P_{od}}} \sum_{a\in p} d_a}
```

````@example basic_shortest_path
# Import relevant packages
using BenchmarkTools
using ConstrainedShortestPaths
using Graphs, SparseArrays
using Random
Random.seed!(67);
nothing #hide
````

````@example basic_shortest_path
function random_acyclic_digraph(nb_vertices::Integer; p=0.4)
    edge_list = []
    for u in 1:nb_vertices
        if u < nb_vertices
            push!(edge_list, (u, u+1))
        end

        for v in (u+2):nb_vertices
            if rand() <= p
                push!(edge_list, (u, v))
            end
        end
    end
    return SimpleDiGraph(Edge.(edge_list))
end;
nothing #hide
````

Let's create a random acyclic directed graph

````@example basic_shortest_path
nb_vertices = 50
g = random_acyclic_digraph(nb_vertices)
adjacency_matrix(g)
````

````@example basic_shortest_path
distance_list = [rand() * 20 - 5 for _ in 1:ne(g)]
I = [src(e) for e in edges(g)]
J = [dst(e) for e in edges(g)]
d = sparse(I, J, distance_list);
nothing #hide
````

aaa

````@example basic_shortest_path
p_star, c_star = basic_shortest_path(g, d)
@info "Solution found" c_star p_star'
````

````@example basic_shortest_path
p = enumerate_paths(bellman_ford_shortest_paths(g, 1, d), nb_vertices)
c = sum(d[p[i], p[i+1]] for i in eachindex(p[1:end-1]))
@info "Bellman" c p'
````

!!! note
    For the usual shortest path, it's probably better to use directly one of the
    shortest paths algorithms from [Graphs.jl](https://juliagraphs.org/Graphs.jl/dev/algorithms/shortestpaths/#Shortest-paths)

````@example basic_shortest_path
@benchmark basic_shortest_path(g, d)
````

````@example basic_shortest_path
@benchmark begin
    p = enumerate_paths(bellman_ford_shortest_paths(g, 1, d), nb_vertices)
    c = sum(d[p[i], p[i+1]] for i in eachindex(p[1:end-1]))
end
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

