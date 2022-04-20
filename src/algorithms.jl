function scan!(graph::MetaDiGraph, vertex::Int, order::Vector{Int}, opened::BitVector)
    opened[vertex] = true
    for neighbour in outneighbors(graph, vertex)
        if opened[neighbour]
            continue
        end
        scan!(graph, neighbour, order, opened)
    end
    push!(order, vertex)
end

function topological_order(graph::MetaDiGraph)
    order = Int[]
    opened = falses(nv(graph))
    scan!(graph, 1, order, opened)
    return order
end

function compute_bounds(instance::RCSPProblem)
    graph = instance.graph
    nb_vertices = nv(instance.graph)

    vertices_order = topological_order(graph)

    bounds = [instance.destination_backward_resource for _ = 1:nb_vertices]
    for vertex in vertices_order[2:end]
        bounds[vertex] = minimum(
            [get_prop(graph, vertex, neighbour, :backward_function)(bounds[neighbour])
             for neighbour in outneighbors(graph, vertex)]
        )
    end

    return bounds
end

function generalized_A_star(instance::RCSPProblem, bounds::Vector)
    graph = instance.graph
    nb_vertices = nv(graph)

    origin = 1
    empty_path = [origin]

    forward_resources = Dict(empty_path => instance.origin_forward_resource)
    L = PriorityQueue{Vector{Int},Float64}(empty_path => instance.cost_function(forward_resources[empty_path], bounds[origin]))
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
            rq = get_prop(graph, v, w, :forward_function)(rp)
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
    return p_star, c_star
end
