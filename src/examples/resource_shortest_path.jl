## Resources

struct RSPResource
    c::Float64
    w::Vector{Float64}
end

function <=(r1::RSPResource, r2::RSPResource)
    if r1.c > r2.c
        return false
    end
    for (w1, w2) in zip(r1.w, r2.w)
        if w1 > w2
            return false
        end
    end
    return true
end

function minimum(R::Vector{RSPResource})
    new_c = minimum(r.c for r in R)
    new_w = zero(R[1].w)
    for i in eachindex(new_w)
        new_w[i] = minimum(r.w[i] for r in R)
    end
    return RSPResource(new_c, new_w)
end


## Expansion functions

struct RSPFunction
    c::Float64
    w::Vector{Float64}
end

function (f::RSPFunction)(q::RSPResource)
    return RSPResource(f.c + q.c, f.w + q.w)
end


## Cost

struct RSPCost
    W::Vector{Float64}
end

function (cost::RSPCost)(fr::RSPResource, br::RSPResource)
    return all(fr.w + br.w .<= cost.W) ? fr.c + br.c : Inf
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
    g::G, max_costs::AbstractVector, distmx::AbstractMatrix, costmx::Array{Float64, 3}
) where {G <: AbstractGraph; IsDirected{G}}
    # origin forward resource and backward forward resource set to 0
    resource = RSPResource(0., zero(max_costs))

    # forward and backward expansion functions are equal
    If = [src(e) for e in edges(g)]
    Jf = [dst(e) for e in edges(g)]
    f = [RSPFunction(distmx[i, j], costmx[i, j, :]) for (i, j) in zip(If, Jf)]
    F = sparse(If, Jf, f)

    instance = RCSPInstance(g, resource, resource, RSPCost(max_costs), F, F)
    return generalized_constrained_shortest_path(instance)
end
