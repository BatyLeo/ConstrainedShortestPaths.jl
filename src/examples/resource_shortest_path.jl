## Resources

struct RSPResource
    c::Float64
    w::Float64
end

function <=(r1::RSPResource, r2::RSPResource)
    return r1.c <= r2.c && r1.w <= r2.w
end

function minimum(R::Vector{RSPResource})
    return RSPResource(minimum(r.c for r in R), minimum(r.w for r in R))
end


## Expansion functions

struct RSPFunction
    c::Float64
    w::Float64
end

function (f::RSPFunction)(q::RSPResource)
    return RSPResource(f.c + q.c, f.w + q.w)
end


## Cost

struct RSPCost
    W::Float64
end

function (cost::RSPCost)(fr::RSPResource, br::RSPResource)
    return fr.w + br.w <= cost.W ? fr.c + br.c : Inf
end

function remove_dominated!(Mw::Vector{RSPResource}, rq::RSPResource)
    to_delete = Int[]
    for (i, r) in enumerate(Mw)
        if rq <= r
            push!(to_delete, i)
        end
    end
    deleteat!(Mw, to_delete)
end

## General wrapper

@traitfn function resource_shortest_path(
    g::G, max_cost::Real, distmx::AbstractMatrix=weights(g), costmx::AbstractMatrix=weights(g)
) where {G <: AbstractGraph; IsDirected{G}}
    # origin forward resource and backward forward resource set to 0
    resource = RSPResource(0., 0.)

    # forward and backward expansion functions are equal
    If = [src(e) for e in edges(g)]
    Jf = [dst(e) for e in edges(g)]
    f = [RSPFunction(distmx[i, j], costmx[i, j]) for (i, j) in zip(If, Jf)]
    F = sparse(If, Jf, f)

    instance = RCSPInstance(g, resource, resource, RSPCost(max_cost), F, F)
    return generalized_constrained_shortest_path(instance)
end
