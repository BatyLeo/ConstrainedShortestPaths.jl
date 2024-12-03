function piecewise_linear(final_slope::Float64=0.0, slack::Float64=0.0, delay::Float64=0.0)
    return PiecewiseLinearFunction([slack], [delay], 0.0, final_slope)
end

"""
$TYPEDEF

# Fields
$TYPEDFIELDS
"""
struct StochasticForwardResource
    "partial cost of the associated path (path cost minus dual varibles)"
    path_cost::Float64
    "propagated delay for each scenario"
    propagated_delays::Vector{Float64}
end

"""
$TYPEDEF

# Fields
$TYPEDFIELDS
"""
struct StochasticBackwardResource
    "piecewise linear function for each scenario, take as input propagated delay and outputs total delay of partail path"
    g::Vector{PiecewiseLinearFunction{Float64}}
end

"""
$TYPEDEF

# Fields
$TYPEDFIELDS
"""
struct StochasticForwardFunction
    "arc slack for each scenario"
    slacks::Vector{Float64}
    "intrinsic delay for each scenario of arc head"
    intrinsic_delays::Vector{Float64}
    "dual variable of arc head"
    λ_value::Float64
end

"""
$TYPEDEF

# Fields
$TYPEDFIELDS
"""
struct StochasticBackwardFunction
    "arc slack for each scenario"
    slacks::Vector{Float64}
    "intrinsic delay for each scenario of arc head"
    intrinsic_delays::Vector{Float64}
    "dual variable of arc head"
    λ_value::Float64
end

function Base.:<=(r1::StochasticForwardResource, r2::StochasticForwardResource)
    if r1.path_cost > r2.path_cost
        return false
    end

    for (x1, x2) in zip(r1.propagated_delays, r2.propagated_delays)
        if x1 > x2
            return false
        end
    end

    return true
end

function Base.min(r1::StochasticBackwardResource, r2::StochasticBackwardResource)
    new_g = min.(r1.g, r2.g)
    return StochasticBackwardResource(new_g)
end

function (f::StochasticForwardFunction)(q::StochasticForwardResource)
    # Total delay at the tail of the arc
    # delays = f.intrinsic_delays + q.propagated_delays
    new_xi = [
        local_delay + max(propagated_delay - slack, 0) for
        (propagated_delay, local_delay, slack) in
        zip(q.propagated_delays, f.intrinsic_delays, f.slacks)
    ]
    # new_propagated_delay = max.(delays .- f.slacks, 0)
    # new_c = q.path_cost + mean(delays) - f.λ_value
    new_c = q.path_cost + mean(new_xi) - f.λ_value
    return StochasticForwardResource(new_c, new_xi), true
end

function _backward_scenario(g::PiecewiseLinearFunction, delay::Float64, slack::Float64, λᵥ)
    f = if slack == Inf
        piecewise_linear()
    else
        piecewise_linear(1.0, slack, delay)
    end
    return f + g ∘ f - λᵥ
end

function (f::StochasticBackwardFunction)(q::StochasticBackwardResource)
    return StochasticBackwardResource([
        _backward_scenario(g, delay, slack, f.λ_value) for
        (g, delay, slack) in zip(q.g, f.intrinsic_delays, f.slacks)
    ])
end

function stochastic_cost(fr::StochasticForwardResource, br::StochasticBackwardResource)
    cp = fr.path_cost + mean(gj(Rj) for (gj, Rj) in zip(br.g, fr.propagated_delays))
    return cp
end

function partial_stochastic_cost(fr::StochasticForwardResource)
    return fr.path_cost
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
    intrinsic_delays::AbstractMatrix,
    λ_values::AbstractVector=zeros(nv(graph));
    origin_vertex::T=one(T),
    destination_vertex::T=nv(graph),
    bounding=true,
) where {T}
    @assert λ_values[origin_vertex] == 0.0 && λ_values[destination_vertex] == 0.0
    @assert all(intrinsic_delays[origin_vertex] .== 0.0)
    @assert all(intrinsic_delays[destination_vertex] .== 0.0)

    nb_scenarios = size(intrinsic_delays, 2)

    origin_forward_resource = StochasticForwardResource(0.0, zeros(nb_scenarios))
    destination_backward_resource = StochasticBackwardResource([
        piecewise_linear() for _ in 1:nb_scenarios
    ])

    I = [src(e) for e in edges(graph)]
    J = [dst(e) for e in edges(graph)]
    ff = [
        StochasticForwardFunction(slacks[u, v], intrinsic_delays[v, :], λ_values[v]) for
        (u, v) in zip(I, J)
    ]
    FF = sparse(I, J, ff)

    instance = if bounding
        bb = [
            StochasticBackwardFunction(slacks[u, v], intrinsic_delays[v, :], λ_values[v]) for (u, v) in zip(I, J)
        ]

        BB = sparse(I, J, bb)

        CSPInstance(;
            graph,
            origin_vertex,
            destination_vertex,
            origin_forward_resource,
            destination_backward_resource,
            cost_function=stochastic_cost,
            forward_functions=FF,
            backward_functions=BB,
        )
    else
        CSPInstance(;
            graph,
            origin_vertex,
            destination_vertex,
            origin_forward_resource,
            cost_function=partial_stochastic_cost,
            forward_functions=FF,
        )
    end
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

    origin_forward_resource = StochasticForwardResource(0.0, delays[1, :])
    destination_backward_resource = StochasticBackwardResource([
        piecewise_linear() for _ in 1:nb_scenarios
    ])

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
