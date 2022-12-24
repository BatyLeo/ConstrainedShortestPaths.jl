const BSPResource = Float64

struct BSPExtensionFunction
    c::BSPResource
end

function (f::BSPExtensionFunction)(q::BSPResource)
    return f.c + q
end

function BSP_cost(qf::BSPResource, qb::BSPResource)
    return qf + qb
end

function remove_dominated!(Mw::Vector{BSPResource}, rq::BSPResource)
    empty!(Mw)
    return Mw = push!(Mw, rq)
end

# Wrapper

"""
    basic_shortest_path(g, distmx=weights(g), s, t)

Compute shortest path between vertices `s` and `t` of graph `g`.

# Arguments
- `g::AbstractGraph`: acyclic directed graph.
- `distmx::AbstractMatrix`: `distmx[i, j]` corresponds to the distance between vertices `i` and `j`
    along edge `(i, j)` of `g`.

# Returns
- `p_star::Vector{Int}`: optimal path found.
- `c_star::Float64`: length of path `p_star`.
"""
@traitfn function basic_shortest_path(
    graph::G, s::T, t::T, distmx::AbstractMatrix=weights(graph)
) where {T,G<:AbstractGraph{T};IsDirected{G}}
    # origin forward resource and backward forward resource set to 0
    resource = 0.0

    # forward and backward Extension functions are equal
    If = [src(e) for e in edges(graph)]
    Jf = [dst(e) for e in edges(graph)]
    f = [BSPExtensionFunction(distmx[i, j]) for (i, j) in zip(If, Jf)]
    F = sparse(If, Jf, f)

    instance = CSPInstance(;
        graph,
        origin_vertex=s,
        destination_vertex=t,
        origin_forward_resource=resource,
        destination_backward_resource=resource,
        cost_function=BSP_cost,
        forward_functions=F,
        backward_functions=F,
    )
    return generalized_constrained_shortest_path(instance)
end
