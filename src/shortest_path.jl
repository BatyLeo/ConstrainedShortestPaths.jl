struct ShortestPathExpansionFunction
    c::Float64
end

function (f::ShortestPathExpansionFunction)(q::Float64)
    return f.c + q
end

function cost(qf::Float64, qb::Float64)
    return qf + qb
end

function remove_dominated!(Mw::Vector{Float64}, rq::Float64)
    empty!(Mw)
    Mw = push!(Mw, rq)
end
