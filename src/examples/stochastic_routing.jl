function piecewise_linear(final_slope::Float64=0.0, slack::Float64=0.0, delay::Float64=0.0)
    return PiecewiseLinearFunction([slack], [delay], 0.0, final_slope)
end

struct StochasticForwardResource
    c::Float64
    xi::Vector{Float64}
    λ::Float64  # sum
end

struct StochasticBackwardResource
    g::Vector{PiecewiseLinearFunction{Float64}}
    λ::Float64
end
struct StochasticForwardFunction
    slacks::Vector{Float64}
    delays::Vector{Float64}
    λ_value::Float64
end

struct StochasticBackwardFunction
    slacks::Vector{Float64}
    delays::Vector{Float64}
    λ_value::Float64
end

function Base.:<=(r1::StochasticForwardResource, r2::StochasticForwardResource)
    if r1.c - r1.λ > r2.c - r2.λ
        return false
    end

    for (x1, x2) in zip(r1.xi, r2.xi)
        if x1 > x2
            return false
        end
    end

    return true
end

function Base.min(r1::StochasticBackwardResource, r2::StochasticBackwardResource)
    new_g = min.(r1.g, r2.g)
    new_λ = max(r1.λ, r2.λ)
    return StochasticBackwardResource(new_g, new_λ)
end

function (f::StochasticForwardFunction)(q::StochasticForwardResource)
    new_xi = [
        local_delay + max(propagated_delay - slack, 0) for
        (propagated_delay, local_delay, slack) in zip(q.xi, f.delays, f.slacks)
    ]
    new_c = q.c + mean(new_xi)
    new_λ = q.λ + f.λ_value
    return StochasticForwardResource(new_c, new_xi, new_λ), true
end

function _backward_scenario(g::PiecewiseLinearFunction, delay::Float64, slack::Float64)
    f = if slack == Inf
        piecewise_linear()
    else
        piecewise_linear(1.0, slack, delay)
    end
    return f + g ∘ f
end

function (f::StochasticBackwardFunction)(q::StochasticBackwardResource)
    return StochasticBackwardResource(
        [
            _backward_scenario(g, delay, slack) for
            (g, delay, slack) in zip(q.g, f.delays, f.slacks)
        ],
        f.λ_value + q.λ,
    )
end

function stochastic_cost(fr::StochasticForwardResource, br::StochasticBackwardResource)
    λ_sum = fr.λ + br.λ
    cp = fr.c + mean(gj(Rj) for (gj, Rj) in zip(br.g, fr.xi))
    return cp - λ_sum
end

## General wrapper

"""
$TYPEDSIGNATURES

Compute stochastic routing shortest path between `origin_vertex` and `destination_vertex` vertices of graph `graph`.

# Arguments
- `graph::AbstractGraph`: acyclic directed graph.
- `slacks`: `slacks[i, j]` corresponds to the time slack between `i` and `j`.
- `delays`: `delays[i, ω]` corresponds to delay of `i` for scenario `ω`.

# Returns
- `p_star::Vector{Int}`: optimal path found.
- `c_star::Float64`: length of path `p_star`.
"""
function stochastic_routing_shortest_path(
    graph::AbstractGraph{T},
    slacks::AbstractMatrix,
    delays::AbstractMatrix,
    λ_values::AbstractVector=zeros(nv(graph));
    origin_vertex::T=one(T),
    destination_vertex::T=nv(graph),
) where {T}
    @assert λ_values[origin_vertex] == 0.0 && λ_values[destination_vertex] == 0.0
    nb_scenarios = size(delays, 2)

    origin_forward_resource = StochasticForwardResource(0.0, delays[1, :], 0)
    destination_backward_resource = StochasticBackwardResource(
        [piecewise_linear() for _ in 1:nb_scenarios], 0
    )

    I = [src(e) for e in edges(graph)]
    J = [dst(e) for e in edges(graph)]
    ff = [
        StochasticForwardFunction(slacks[u, v], delays[v, :], λ_values[v]) for
        (u, v) in zip(I, J)
    ]
    bb = [
        StochasticBackwardFunction(slacks[u, v], delays[v, :], λ_values[v]) for
        (u, v) in zip(I, J)
    ]

    FF = sparse(I, J, ff)
    BB = sparse(I, J, bb)

    instance = CSPInstance(;
        graph,
        origin_vertex,
        destination_vertex,
        origin_forward_resource,
        destination_backward_resource,
        cost_function=stochastic_cost,
        forward_functions=FF,
        backward_functions=BB,
    )
    return generalized_constrained_shortest_path(instance)
end

"""
$TYPEDSIGNATURES

Compute stochastic routing shortest path between first and last vertices of graph `graph`.
"""
function stochastic_routing_shortest_path_with_threshold(
    graph::AbstractGraph,
    slacks::AbstractMatrix,
    delays::AbstractMatrix,
    λ_values::AbstractVector=zeros(nv(graph));
    threshold,
)
    nb_scenarios = size(delays, 2)

    origin_forward_resource = StochasticForwardResource(0.0, delays[1, :], 0)
    destination_backward_resource = StochasticBackwardResource(
        [piecewise_linear() for _ in 1:nb_scenarios], 0
    )

    I = [src(e) for e in edges(graph)]
    J = [dst(e) for e in edges(graph)]
    ff = [
        StochasticForwardFunction(slacks[u, v], delays[v, :], λ_values[v]) for
        (u, v) in zip(I, J)
    ]
    bb = [
        StochasticBackwardFunction(slacks[u, v], delays[v, :], λ_values[v]) for
        (u, v) in zip(I, J)
    ]

    FF = sparse(I, J, ff)
    BB = sparse(I, J, bb)

    instance = CSPInstance(;
        graph,
        origin_vertex=1,
        destination_vertex=nv(graph),
        origin_forward_resource,
        destination_backward_resource,
        cost_function=stochastic_cost,
        forward_functions=FF,
        backward_functions=BB,
    )
    return generalized_constrained_shortest_path_with_threshold(instance, threshold)
end
