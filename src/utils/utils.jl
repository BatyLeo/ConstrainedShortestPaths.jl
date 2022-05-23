function is_dominated(rq::F, Mw::Vector{F}) where F
    for r in Mw
        if r <= rq
            return true
        end
    end
    return false
end

# Topological order computing
@traitfn function scan!(graph::G, vertex::Int, order::Vector{Int}, opened::BitVector) where {G; IsDirected{G}}
    opened[vertex] = true
    for neighbour in outneighbors(graph, vertex)
        if opened[neighbour]
            continue
        end
        scan!(graph, neighbour, order, opened)
    end
    push!(order, vertex)
end

@traitfn function topological_order(graph::G) where {G; IsDirected{G}}
    order = Int[]
    opened = falses(nv(graph))
    scan!(graph, 1, order, opened)
    return order
end

function remove_dominated!(Mw::AbstractVector{R}, rq::R) where R
    to_delete = Int[]
    for (i, r) in enumerate(Mw)
        if rq <= r
            push!(to_delete, i)
        end
    end
    deleteat!(Mw, to_delete)
end
