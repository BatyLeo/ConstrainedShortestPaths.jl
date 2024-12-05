function piecewise_linear(final_slope::Float64=0.0, slack::Float64=0.0, delay::Float64=0.0)
    return PiecewiseLinearFunction([slack], [delay], 0.0, final_slope)
end

"""
$TYPEDEF

# Fields
$TYPEDFIELDS
"""
struct StochasticForwardResource
    "partial cost of the associated path (not counting task at end of path)"
    path_cost::Float64
    "current task (end of path) delay for each scenario"
    delays::Vector{Float64}
end

"""
$TYPEDEF

# Fields
$TYPEDFIELDS
"""
struct StochasticBackwardResource{is_convex}
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
    "dual variable of arc tail"
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

    for (x1, x2) in zip(r1.delays, r2.delays)
        if x1 > x2
            return false
        end
    end

    return true
end

function Base.min(
    r1::StochasticBackwardResource{true}, r2::StochasticBackwardResource{true}
)
    new_g = convex_meet.(r1.g, r2.g)
    # new_g = remove_redundant_breakpoints.(convex_meet.(r1.g, r2.g); atol=1e-8)
    return StochasticBackwardResource{true}(new_g)
end

function Base.min(
    r1::StochasticBackwardResource{false}, r2::StochasticBackwardResource{false}
)
    new_g = min.(r1.g, r2.g)
    return StochasticBackwardResource{false}(new_g)
end

function (f::StochasticForwardFunction)(q::StochasticForwardResource)
    new_xi = f.intrinsic_delays .+ max.(q.delays .- f.slacks, 0)
    new_c = q.path_cost + mean(q.delays) - f.λ_value
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

function (f::StochasticBackwardFunction)(
    q::StochasticBackwardResource{is_convex}
) where {is_convex}
    return StochasticBackwardResource{is_convex}([
        _backward_scenario(g, delay, slack, f.λ_value) for
        (g, delay, slack) in zip(q.g, f.intrinsic_delays, f.slacks)
    ])
end

function stochastic_cost(fr::StochasticForwardResource, br::StochasticBackwardResource)
    cp = fr.path_cost + mean(gj(Rj) for (gj, Rj) in zip(br.g, fr.delays))
    return cp
end

function partial_stochastic_cost(fr::StochasticForwardResource)
    return fr.path_cost
end

## General wrapper

function create_instance(
    graph::AbstractGraph{T},
    slacks::AbstractMatrix,
    intrinsic_delays::AbstractMatrix,
    λ_values::AbstractVector=zeros(nv(graph));
    origin_vertex::T=one(T),
    destination_vertex::T=nv(graph),
    bounding=true,
    use_convex_resources=true,
) where {T}
    @assert λ_values[origin_vertex] == 0.0 && λ_values[destination_vertex] == 0.0
    @assert all(intrinsic_delays[origin_vertex] .== 0.0)
    @assert all(intrinsic_delays[destination_vertex] .== 0.0)

    nb_scenarios = size(intrinsic_delays, 2)

    origin_forward_resource = StochasticForwardResource(0.0, zeros(nb_scenarios))

    I = [src(e) for e in edges(graph)]
    J = [dst(e) for e in edges(graph)]

    ff = [
        StochasticForwardFunction(slacks[u, v], intrinsic_delays[v, :], λ_values[v]) for
        (u, v) in zip(I, J)
    ]
    FF = sparse(I, J, ff)

    if bounding
        bb = [
            StochasticBackwardFunction(slacks[u, v], intrinsic_delays[v, :], λ_values[v])
            for (u, v) in zip(I, J)
        ]
        destination_backward_resource = StochasticBackwardResource{use_convex_resources}([
            piecewise_linear() for _ in 1:nb_scenarios
        ])

        BB = sparse(I, J, bb)

        return CSPInstance(;
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
        return CSPInstance(;
            graph,
            origin_vertex,
            destination_vertex,
            origin_forward_resource,
            cost_function=partial_stochastic_cost,
            forward_functions=FF,
        )
    end
end

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
    use_convex_resources=true,
) where {T}
    instance = create_instance(
        graph,
        slacks,
        intrinsic_delays,
        λ_values;
        origin_vertex=origin_vertex,
        destination_vertex=destination_vertex,
        bounding=bounding,
        use_convex_resources=use_convex_resources,
    )
    return generalized_constrained_shortest_path(instance)
end

"""
$TYPEDSIGNATURES

Threshold version of [`stochastic_routing_shortest_path`](@ref).
"""
function stochastic_routing_shortest_path_with_threshold(
    graph::AbstractGraph{T},
    slacks::AbstractMatrix,
    delays::AbstractMatrix,
    λ_values::AbstractVector=zeros(nv(graph));
    origin_vertex::T=one(T),
    destination_vertex::T=nv(graph),
    bounding=true,
    use_convex_resources=true,
    threshold,
) where {T}
    instance = create_instance(
        graph,
        slacks,
        delays,
        λ_values;
        bounding=bounding,
        origin_vertex=origin_vertex,
        destination_vertex=destination_vertex,
        use_convex_resources=use_convex_resources,
    )
    return generalized_constrained_shortest_path_with_threshold(instance, threshold)
end
