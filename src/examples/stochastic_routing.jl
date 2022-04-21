struct StochasticForwardResource
    c::Float64
    xi::Vector{Float64}
end

function <=(r1::StochasticForwardResource, r2::StochasticForwardResource)
    if r1.c > r2.c
        return false
    end

    for (x1, x2) in zip(r1.xi, r2.xi)
        if x1 > x2
            return false
        end
    end

    return true
end

struct StochasticForwardFunction
    slack::Float64
    delays::Vector{Float64}
end

function (f::StochasticForwardFunction)(q::StochasticForwardResource)
    m = length(f.delays)
    slack = f.slack

    new_xi = [
        max(propagated_delay - slack, 0) + local_delay for
        (propagated_delay, local_delay) in zip(q.xi, f.delays)
    ]
    new_c = q.c + sum(new_xi) / m
    return StochasticForwardResource(new_c, new_xi)
end

struct StochasticBackwardResource{F}
    g::Vector{F}
end

function minimum(r1::StochasticBackwardResource, r2::StochasticBackwardResource)
    return [R -> min(g1(R), g2(R)) for (g1, g2) in zip(r1.g, r2.g)]
end

function mini(r::Vector)
    m = length(r[1].g)
    return StochasticBackwardResource([R -> minimum(g.g[i](R) for g in r) for i in 1:m])
end

struct StochasticBackwardFunction
    slack::Float64
    delays::Vector{Float64}
end

function (f::StochasticBackwardFunction)(q::StochasticBackwardResource)
    m = length(q.g)
    slack = f.slack
    return StochasticBackwardResource([
        function (R::Float64)
            raj = max(R - slack, 0) + delay
            return raj + g(raj)
        end for (delay, g) in zip(f.delays, q.g)
    ])
end

function cost(fr::StochasticForwardResource, br::StochasticBackwardResource)
    m = length(fr.xi)
    return fr.c + sum(gj[Rj] for (gj, Rj) in zip(br.g, fr.xi)) / m
end

function remove_dominated!(Mw::Vector{StochasticForwardResource}, rq::StochasticForwardResource)
    to_delete = Int[]
    for (i, r) in enumerate(Mw)
        if rq <= r
            push!(to_delete, i)
        end
    end
    deleteat!(Mw, to_delete)
end
