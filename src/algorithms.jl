"""
    CSPInstance{G,FR,BR,C,FF,BF}

# Attributes

- `graph`
- `origin_forward_resource`
- `destination_backward_resource`
- `cost_function`
- `forward_functions`
- `backward_functions`
"""
Base.@kwdef struct CSPInstance{
    T,G<:AbstractGraph{T},FR,BR,C,FF<:AbstractMatrix,BF<:AbstractMatrix
}
    graph::G  # assumption : node 1 is origin, last node is destination
    origin_vertex::T
    destination_vertex::T
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
    instance::CSPInstance{T,G}; kwargs...
) where {T,G<:AbstractGraph{T};IsDirected{G}}
    (; graph, origin_vertex, destination_vertex) = instance

    vertices_order = topological_order(graph, origin_vertex, destination_vertex)

    bounds = Dict{Int,typeof(instance.destination_backward_resource)}()
    # bounds = Vector{typeof(instance.destination_backward_resource)}(undef, nb_vertices)
    bounds[destination_vertex] = instance.destination_backward_resource

    for vertex in vertices_order[2:end]
        vector = [
            instance.backward_functions[vertex, neighbor](bounds[neighbor]; kwargs...) for
            neighbor in outneighbors(graph, vertex) if haskey(bounds, neighbor)
        ]
        bounds[vertex] = minimum(vector)
    end

    return bounds
end

"""
    generalized_a_star(instance, s, t, bounds)

Perform generalized A star algorithm on instnace using bounds
(see [Generalized `A^\\star`](@ref)).
"""
@traitfn function generalized_a_star(
    instance::CSPInstance{T,G}, bounds::AbstractDict; kwargs...
) where {T,G<:AbstractGraph{T};IsDirected{G}}
    (; graph, origin_vertex, destination_vertex) = instance
    nb_vertices = nv(graph)

    empty_path = [origin_vertex]

    forward_resources = Dict(empty_path => instance.origin_forward_resource)
    L = PriorityQueue{Vector{Int},Float64}(
        empty_path =>
            instance.cost_function(forward_resources[empty_path], bounds[origin_vertex]),
    )

    forward_type = typeof(forward_resources[empty_path])
    M = [forward_type[] for _ in 1:nb_vertices]
    push!(M[origin_vertex], forward_resources[empty_path])
    c_star = Inf
    p_star = [origin_vertex]

    while !isempty(L)
        p = dequeue!(L)
        v = p[end]
        for w in outneighbors(graph, v)
            if !haskey(bounds, w)
                continue
            end
            q = copy(p)
            push!(q, w)
            rp = forward_resources[p]
            rq, is_feasible = instance.forward_functions[v, w](rp; kwargs...)
            if !is_feasible
                continue
            end
            forward_resources[q] = rq
            c = instance.cost_function(rq, bounds[w])
            if c < c_star # cut using bounds
                if w == destination_vertex # if destination is reached
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
    return (; p_star, c_star)
end

"""
    generalized_a_star_with_threshold(instance, bounds, threshold)

Compute all paths below threshold.
"""
@traitfn function generalized_a_star_with_threshold(
    instance::CSPInstance{T,G}, bounds::AbstractDict, threshold::Float64; kwargs...
) where {T,G<:AbstractGraph;IsDirected{G}}
    (; graph, origin_vertex, destination_vertex) = instance

    empty_path = [origin_vertex]

    forward_resources = Dict(empty_path => instance.origin_forward_resource)
    L = PriorityQueue{Vector{Int},Float64}(
        empty_path =>
            instance.cost_function(forward_resources[empty_path], bounds[origin_vertex]),
    )

    c_star = Float64[]
    p_star = Vector{Int}[]

    while !isempty(L)
        p = dequeue!(L)
        v = p[end]
        for w in outneighbors(graph, v)
            q = copy(p)
            push!(q, w)
            rp = forward_resources[p]
            rq, is_feasible = instance.forward_functions[v, w](rp; kwargs...)
            if !is_feasible
                continue
            end
            forward_resources[q] = rq
            c = instance.cost_function(rq, bounds[w])
            if c < threshold
                if w == destination_vertex # if destination is reached
                    push!(p_star, copy(q))
                    push!(c_star, c)
                else # else add path to queue
                    enqueue!(L, q => c)
                end
            end
            # else, discard path (i.e. do nothing)
        end
    end
    return (; p_star, c_star)
end

"""
    generalized_constrained_shortest_path(instance, s, t)

Compute the shortest path of `instance`.
"""
@traitfn function generalized_constrained_shortest_path(
    instance::CSPInstance{T,G}; kwargs...
) where {T,G<:AbstractGraph{T};IsDirected{G}}
    bounds = compute_bounds(instance; kwargs...)
    return generalized_a_star(instance, bounds; kwargs...)
end

"""
    generalized_constrained_shortest_path(instance)

Compute shortest path between first and last nodes of `instance`
"""
@traitfn function generalized_constrained_shortest_path_with_threshold(
    instance::CSPInstance{T,G}, threshold::Float64; kwargs...
) where {T,G<:AbstractGraph;IsDirected{G}}
    bounds = compute_bounds(instance; kwargs...)
    return generalized_a_star_with_threshold(instance, bounds, threshold; kwargs...)
end
