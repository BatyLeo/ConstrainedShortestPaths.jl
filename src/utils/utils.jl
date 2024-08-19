function is_dominated(rq::F, Mw::Vector{F}) where {F}
    for r in Mw
        if r <= rq
            return true
        end
    end
    return false
end

function remove_dominated!(Mw::AbstractVector{R}, rq::R) where {R}
    to_delete = Int[]
    for (i, r) in enumerate(Mw)
        if rq <= r
            push!(to_delete, i)
        end
    end
    deleteat!(Mw, to_delete)
    return nothing
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
    order = Int[]
    opened = falses(nv(graph))
    scan!(graph, s, order, opened)

    start = findfirst(x -> (x == t), order)  # Can we do smarter than that ?
    @assert !isnothing(start)
    return order[start:end]
end
