"""
    RCSPInstance{G,FR,BR,C,FF,BF}

# Attributes

- `graph`:
- `origin_forward_resource`:
- `destination_backward_resource`:
- `cost_function`:
- `forward_functions`:
- `backward_functions`:
"""
struct RCSPInstance{G,FR,BR,C,FF<:AbstractMatrix,BF<:AbstractMatrix}
    graph::G  # assumption : node 1 is origin, last node is destination
    origin_forward_resource::FR
    destination_backward_resource::BR
    cost_function::C
    forward_functions::FF
    backward_functions::BF
end

"""
    compute_bounds(instance)

aa
"""
@traitfn function compute_bounds(
    instance::RCSPInstance{G}
) where {G <: AbstractGraph; IsDirected{G}}
    graph = instance.graph
    nb_vertices = nv(instance.graph)

    vertices_order = topological_order(graph)
    bounds = [instance.destination_backward_resource for _ = 1:nb_vertices]
    for vertex in vertices_order[2:end]
        vector = [instance.backward_functions[vertex, neighbor](bounds[neighbor])
            for neighbor in outneighbors(graph, vertex)]
        bounds[vertex] = minimum(vector)
    end

    return bounds
end

"""
    generalized_A_star(instance, bounds)

aa
"""
@traitfn function generalized_A_star(
    instance::RCSPInstance{G}, bounds::AbstractVector
) where {G <: AbstractGraph; IsDirected{G}}
    graph = instance.graph
    nb_vertices = nv(graph)

    origin = 1
    empty_path = [origin]

    forward_resources = Dict(empty_path => instance.origin_forward_resource)
    L = PriorityQueue{Vector{Int},Float64}(
        empty_path => instance.cost_function(forward_resources[empty_path], bounds[origin])
    )
    M = [typeof(forward_resources[empty_path])[] for _ in 1:nb_vertices]
    push!(M[origin], forward_resources[empty_path])
    c_star = Inf
    p_star = [origin]  # undef

    while length(L) > 0
        p = dequeue!(L)
        v = p[end]
        for w in outneighbors(graph, v)
            q = copy(p)
            push!(q, w)
            rp = forward_resources[p]
            rq = instance.forward_functions[v, w](rp)
            forward_resources[q] = rq
            c = instance.cost_function(rq, bounds[w])
            if w == nb_vertices && c < c_star
                c_star = c
                p_star = copy(q)
            elseif !is_dominated(rq, M[w]) && c < c_star
                remove_dominated!(M[w], rq)
                push!(M[w], rq)
                enqueue!(L, q => c)
            end
        end
    end
    return (p_star=p_star, c_star=c_star)
end

"""
    generalized_constrained_shortest_path(instance)

aa
"""
@traitfn function generalized_constrained_shortest_path(
    instance::RCSPInstance{G}
) where {G <: AbstractGraph; IsDirected{G}}
    bounds = compute_bounds(instance)
    return generalized_A_star(instance, bounds)
end
