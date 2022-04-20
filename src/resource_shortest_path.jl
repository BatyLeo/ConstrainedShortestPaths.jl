## Resources

struct CSPResource
    c::Float64
    w::Float64
end

function <=(r1::CSPResource, r2::CSPResource)
    return r1.c <= r2.c && r1.w <= r2.w 
end

function minimum(R::Vector{CSPResource})
    return CSPResource(minimum(r.c for r in R), minimum(r.w for r in R))
end


## Functions

struct CSPFunction
    c::Float64
    w::Float64
end

function (f::CSPFunction)(q::CSPResource)
    return CSPResource(f.c + q.c, f.w + q.w)
end


## Cost

struct CSPCost
    W::Float64
end

function (cost::CSPCost)(fr::CSPResource, br::CSPResource)
    return fr.w + br.w <= cost.W ? fr.c + br.c : Inf
end

function remove_dominated!(Mw::Vector{CSPResource}, rq::CSPResource)
    to_delete = Int[]
    for (i, r) in enumerate(Mw)
        if rq <= r
            push!(to_delete, i)
        end
    end
    deleteat!(Mw, to_delete)
end
