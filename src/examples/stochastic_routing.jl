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

struct StochasticBackwardResource
    g::Vector{PiecewiseLinear}
end

function minimum(r1::StochasticBackwardResource, r2::StochasticBackwardResource)
    return [meet(g1, g2) for (g1, g2) in zip(r1.g, r2.g)]
end

function minimum(r::Vector{StochasticBackwardResource})
    res = r[1]
    for resource in r[2:end]
        res = meet(res, resource)
    end
    return res
end

struct StochasticBackwardFunction
    slack::Float64
    delays::Vector{Float64}
end

function (f::StochasticBackwardFunction)(q::StochasticBackwardResource)
    slack = f.slack
    return StochasticBackwardResource([
        PiecewiseLinear(1.0, [slack], [delay]) + compose(g, PiecewiseLinear(1.0, [slack], [delay]))
    for (delay, g) in zip(f.delays, q.g)])
end

function stochastic_cost(fr::StochasticForwardResource, br::StochasticBackwardResource)
    m = length(fr.xi)
    return fr.c + sum(gj(Rj) for (gj, Rj) in zip(br.g, fr.xi)) / m
end

## General wrapper

"""
    stochastic_routing_shortest_path(g, slacks, delays)

Args:
- g: acyclic directed graph
- slacks: [i, j]
- delays: [i, ω]
"""
@traitfn function stochastic_routing_shortest_path(
    g::G, slacks::AbstractMatrix, delays::AbstractMatrix
) where {G <: AbstractGraph; IsDirected{G}}
    nb_scenarios = size(delays, 2)

    origin_forward_resource = StochasticForwardResource(0.0, [0.0 for _ = 1:nb_scenarios])
    destination_backward_resource = StochasticBackwardResource([PiecewiseLinear() for _ = 1:nb_scenarios])

    I = [src(e) for e in edges(g)]
    J = [dst(e) for e in edges(g)]
    ff = [StochasticForwardFunction(slacks[i, j], delays[i, :]) for (i, j) in zip(I, J)]
    bb = [StochasticBackwardFunction(slacks[i, j], delays[i, :]) for (i, j) in zip(I, J)]

    FF = sparse(I, J, ff)
    BB = sparse(I, J, bb)

    instance = RCSPInstance(g, origin_forward_resource, destination_backward_resource, stochastic_cost, FF, BB)
    return generalized_constrained_shortest_path(instance)
end
