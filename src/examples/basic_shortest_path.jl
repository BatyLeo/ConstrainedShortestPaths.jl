const BSPResource = Float64

struct BSPForwardExtensionFunction
    c::BSPResource
end

function (f::BSPForwardExtensionFunction)(q::BSPResource)
    return f.c + q, true
end

struct BSPBackwardExtensionFunction
    c::BSPResource
end

function (f::BSPBackwardExtensionFunction)(q::BSPResource)
    return f.c + q
end

function remove_dominated!(Mw::Vector{BSPResource}, rq::BSPResource)
    empty!(Mw)
    return Mw = push!(Mw, rq)
end

# Wrapper

"""
$TYPEDSIGNATURES

Compute shortest path between vertices `s` and `t` of graph `graph`.

# Arguments
- `graph::AbstractGraph`: acyclic directed graph.
- `distmx::AbstractMatrix`: `distmx[i, j]` corresponds to the distance between vertices `i` and `j`
    along edge `(i, j)` of `graph`.

# Returns
- `p_star::Vector{Int}`: optimal path found.
- `c_star::Float64`: length of path `p_star`.
"""
function basic_shortest_path(
    graph::AbstractGraph{T},
    s::T,
    t::T,
    distmx::AbstractMatrix=weights(graph);
    bounding=true,
) where {T}
    # origin forward resource and backward forward resource set to 0
    resource = 0.0

    # forward and backward Extension functions are equal
    If = [src(e) for e in edges(graph)]
    Jf = [dst(e) for e in edges(graph)]
    ff = [BSPForwardExtensionFunction(distmx[i, j]) for (i, j) in zip(If, Jf)]
    FF = sparse(If, Jf, ff)

    instance = if bounding
        fb = [BSPBackwardExtensionFunction(distmx[i, j]) for (i, j) in zip(If, Jf)]
        FB = sparse(If, Jf, fb)

        CSPInstance(;
            graph,
            origin_vertex=s,
            destination_vertex=t,
            origin_forward_resource=resource,
            destination_backward_resource=resource,
            cost_function=Base.:+,
            forward_functions=FF,
            backward_functions=FB,
        )
    else
        CSPInstance(;
            graph,
            origin_vertex=s,
            destination_vertex=t,
            origin_forward_resource=resource,
            cost_function=identity,
            forward_functions=FF,
        )
    end
    return generalized_constrained_shortest_path(instance)
end
