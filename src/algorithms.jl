"""
    CSPInstance{G,FR,BR,C,FF,BF}

# Attributes

- `graph`:
- `origin_forward_resource`:
- `destination_backward_resource`:
- `cost_function`:
- `forward_functions`:
- `backward_functions`:
"""
struct CSPInstance{G,FR,BR,C,FF<:AbstractMatrix,BF<:AbstractMatrix}
    graph::G  # assumption : node 1 is origin, last node is destination
    origin_forward_resource::FR
    destination_backward_resource::BR
    cost_function::C
    forward_functions::FF
    backward_functions::BF
end

"""
    compute_bounds(instance)

Compute backward bounds of instance (see [Computing bounds](@ref)).
"""
@traitfn function compute_bounds(
    instance::CSPInstance{G}, s::Int, t::Int
) where {G <: AbstractGraph; IsDirected{G}}
    graph = instance.graph
    nb_vertices = nv(instance.graph)

    vertices_order = topological_order(graph, s, t)
    bounds = Vector{typeof(instance.destination_backward_resource)}(undef, nb_vertices)
    bounds[t] = instance.destination_backward_resource
    for vertex in vertices_order[2:end]
        vector = [instance.backward_functions[vertex, neighbor](bounds[neighbor])
            for neighbor in outneighbors(graph, vertex)]
        bounds[vertex] = minimum(vector)
    end

    return bounds
end

"""
    generalized_A_star(instance, bounds)

Perform generalized A star algorithm on instnace using bounds
(see [Generalized `A^\\star`](@ref)).
"""
@traitfn function generalized_A_star(
    instance::CSPInstance{G}, s::Int, t::Int, bounds::AbstractVector
) where {G <: AbstractGraph; IsDirected{G}}
    graph = instance.graph
    nb_vertices = nv(graph)

    empty_path = [s]

    forward_resources = Dict(empty_path => instance.origin_forward_resource)
    L = PriorityQueue{Vector{Int},Float64}(
        empty_path => instance.cost_function(forward_resources[empty_path], bounds[s])
    )

    forward_type = typeof(forward_resources[empty_path])
    M = [forward_type[] for _ in 1:nb_vertices]
    push!(M[s], forward_resources[empty_path])
    c_star = Inf
    p_star = [s]

    while !isempty(L)
        p = dequeue!(L)
        v = p[end]
        for w in outneighbors(graph, v)
            q = copy(p)
            push!(q, w)
            rp = forward_resources[p]
            rq = instance.forward_functions[v, w](rp)
            forward_resources[q] = rq
            c = instance.cost_function(rq, bounds[w])
            if c < c_star # cut using bounds
                if w == t # if destination is reached
                    c_star = c
                    p_star = copy(q)
                elseif !is_dominated(rq, M[w]) # else add path to queue if not dominated
                    remove_dominated!(M[w], rq)
                    push!(M[w], rq)
                    enqueue!(L, q => c)
                end
            end
        end
    end
    return (p_star=p_star, c_star=c_star)
end

"""
    generalized_constrained_shortest_path(instance)

Compute shortest path between first and last nodes of `instance`
"""
@traitfn function generalized_constrained_shortest_path(
    instance::CSPInstance{G}, s::Int, t::Int
) where {G <: AbstractGraph; IsDirected{G}}
    bounds = compute_bounds(instance, s, t)
    return generalized_A_star(instance, s, t, bounds)
end

@traitfn function generalized_constrained_shortest_path(
    instance::CSPInstance{G}
) where {G <: AbstractGraph; IsDirected{G}}
    return generalized_constrained_shortest_path(instance, 1, nv(instance.graph))
end
