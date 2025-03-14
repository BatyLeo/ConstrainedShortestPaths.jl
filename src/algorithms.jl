"""
$TYPEDSIGNATURES

Compute backward bounds of instance (see [Computing bounds](@ref)).
"""
function compute_bounds(instance::CSPInstance{T,G,FR,BR}; kwargs...) where {T,G,FR,BR}
    (; graph, destination_vertex, topological_ordering, is_useful) = instance

    vertices_order = topological_ordering
    @assert vertices_order[1] == destination_vertex

    bounds = Dict{Int,BR}()
    # bounds = Vector{typeof(instance.destination_backward_resource)}(undef, nv(graph))
    bounds[destination_vertex] = instance.destination_backward_resource

    for vertex in vertices_order[2:end]
        vector = [
            instance.backward_functions[vertex, neighbor](bounds[neighbor]; kwargs...) for
            neighbor in outneighbors(graph, vertex) if is_useful[neighbor]
        ]
        bounds[vertex] = minimum(vector)
    end

    return bounds
end

"""
$TYPEDSIGNATURES

Perform generalized A star algorithm on instnace using bounds
(see [Generalized `A^\\star`](@ref)).
"""
function generalized_a_star(instance::CSPInstance{T,G,FR}, bounds; kwargs...) where {T,G,FR}
    (; graph, origin_vertex, destination_vertex, is_useful) = instance
    nb_vertices = nv(graph)

    empty_path = [origin_vertex]

    forward_resources = Dict(empty_path => instance.origin_forward_resource)
    L = PriorityQueue{Vector{Int},Float64}(
        empty_path =>
            instance.cost_function(forward_resources[empty_path], bounds[origin_vertex]),
    )

    # forward_type = typeof(forward_resources[empty_path])
    M = [FR[] for _ in 1:nb_vertices]
    push!(M[origin_vertex], forward_resources[empty_path])
    c_star = Inf
    p_star = [origin_vertex]

    nb_cuts_with_bounds = 0
    nb_cuts_with_dominance = 0

    while !isempty(L)
        p = dequeue!(L)
        v = p[end]
        for w in outneighbors(graph, v)
            if !is_useful[w]
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
                else
                    nb_cuts_with_dominance += 1
                end
            else
                nb_cuts_with_bounds += 1
            end
        end
    end
    info = (; nb_cuts_with_bounds, nb_cuts_with_dominance)
    return (; p_star, c_star, info, bounds)
end

"""
$TYPEDSIGNATURES

Label dominance dynamic programming without bounding.
"""
function generalized_a_star(instance::ForwardCSPInstance; kwargs...)
    (; graph, origin_vertex, destination_vertex, is_useful) = instance
    nb_vertices = nv(graph)

    empty_path = [origin_vertex]

    forward_resources = Dict(empty_path => instance.origin_forward_resource)
    L = PriorityQueue{Vector{Int},Float64}(
        empty_path => instance.cost_function(forward_resources[empty_path])
    )

    forward_type = typeof(forward_resources[empty_path])
    M = [forward_type[] for _ in 1:nb_vertices]
    push!(M[origin_vertex], forward_resources[empty_path])
    c_star = Inf
    p_star = [origin_vertex]
    nb_cuts_with_dominance = 0

    while !isempty(L)
        p = dequeue!(L)
        v = p[end]
        for w in outneighbors(graph, v)
            if !is_useful[w]
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
            c = instance.cost_function(rq) # compute partial cost
            if w == destination_vertex # if destination is reached
                if c < c_star
                    c_star = c
                    p_star = copy(q)
                end
            elseif !is_dominated(rq, M[w]) # else add path to queue if not dominated
                remove_dominated!(M[w], rq)
                push!(M[w], rq)
                enqueue!(L, q => c)
            else
                nb_cuts_with_dominance += 1
            end
        end
    end
    info = (; nb_cuts_with_dominance)
    return (; p_star, c_star, info)
end

"""
$TYPEDSIGNATURES

Compute all paths below threshold.
"""
function generalized_a_star_with_threshold(
    instance::CSPInstance, bounds, threshold::Float64; kwargs...
)
    (; graph, origin_vertex, destination_vertex, is_useful) = instance

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
            if !is_useful[w]
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
$TYPEDSIGNATURES

Compute all paths below threshold.
"""
function generalized_a_star_with_threshold(
    instance::ForwardCSPInstance, threshold::Float64; kwargs...
)
    (; graph, origin_vertex, destination_vertex, is_useful) = instance

    empty_path = [origin_vertex]

    forward_resources = Dict(empty_path => instance.origin_forward_resource)
    L = PriorityQueue{Vector{Int},Float64}(
        empty_path => instance.cost_function(forward_resources[empty_path])
    )

    c_star = Float64[]
    p_star = Vector{Int}[]

    while !isempty(L)
        p = dequeue!(L)
        v = p[end]
        for w in outneighbors(graph, v)
            if !is_useful[w]
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
            c = instance.cost_function(rq)
            if w == destination_vertex # if destination is reached
                if c < threshold
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
$TYPEDSIGNATURES

Compute the shortest path of `instance`.
"""
function generalized_constrained_shortest_path(instance::CSPInstance; kwargs...)
    bounds = compute_bounds(instance; kwargs...)
    return generalized_a_star(instance, bounds; kwargs...)
end

function generalized_constrained_shortest_path(instance::ForwardCSPInstance; kwargs...)
    return generalized_a_star(instance; kwargs...)
end

"""
$TYPEDSIGNATURES

Compute shortest path between first and last nodes of `instance`
"""
function generalized_constrained_shortest_path_with_threshold(
    instance::CSPInstance, threshold::Float64; kwargs...
)
    bounds = compute_bounds(instance; kwargs...)
    return generalized_a_star_with_threshold(instance, bounds, threshold; kwargs...)
end

function generalized_constrained_shortest_path_with_threshold(
    instance::ForwardCSPInstance, threshold::Float64; kwargs...
)
    return generalized_a_star_with_threshold(instance, threshold; kwargs...)
end
