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
    Mw = push!(Mw, rq)
end

@traitfn function basic_shortest_path(
    g::G, distmx::AbstractMatrix=weights(g)
) where {G <: AbstractGraph; IsDirected{G}}
    # origin forward resource and backward forward resource set to 0
    resource = 0.0

    # forward and backward Extension functions are equal
    If = [src(e) for e in edges(g)]
    Jf = [dst(e) for e in edges(g)]
    f = [BSPExtensionFunction(distmx[i, j]) for (i, j) in zip(If, Jf)]
    F = sparse(If, Jf, f)

    instance = RCSPInstance(g, resource, resource, BSP_cost, F, F)
    return generalized_constrained_shortest_path(instance)
end
