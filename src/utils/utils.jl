function is_dominated(rq::F, Mw::Vector{F}) where {F}
    for r in Mw
        if r <= rq
            return true
        end
    end
    return false
end

# Remove all elements in Mw that are dominated by rq
function remove_dominated!(Mw::AbstractVector{R}, rq::R) where {R}
    filter!(r -> !(rq <= r), Mw)
    return nothing
end

function dfs(graph::G, v::T; out=true) where {T,G<:AbstractGraph{T}}
    visited = falses(nv(graph))
    stack = [v]
    while !isempty(stack)
        v = pop!(stack)
        if visited[v]
            continue
        end
        visited[v] = true
        for w in (out ? outneighbors(graph, v) : inneighbors(graph, v))
            push!(stack, w)
        end
    end
    return visited
end

# Topological order computing
function scan!(
    graph::G, vertex::T, order::Vector{T}, opened::BitVector
) where {T,G<:AbstractGraph{T}}
    opened[vertex] = true
    for neighbour in outneighbors(graph, vertex)
        if opened[neighbour]
            continue
        end
        scan!(graph, neighbour, order, opened)
    end
    push!(order, vertex)
    return nothing
end

function topological_order(graph::G, s::T, t::T) where {T,G<:AbstractGraph{T}}
    s_visited = dfs(graph, s; out=true)
    t_visited = dfs(graph, t; out=false)
    visited = s_visited .& t_visited

    order = Int[]
    opened = falses(nv(graph))
    scan!(graph, s, order, opened)

    res = [o for o in order if visited[o]]
    @assert res[1] == t
    return res

    # start = findfirst(x -> (x == t), order)  # Can we do smarter than that ?
    # @assert !isnothing(start)
    # return order[start:end]
end
