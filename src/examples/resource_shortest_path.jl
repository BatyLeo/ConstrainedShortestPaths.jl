## Resources

struct RSPResource
    c::Float64
    w::Vector{Float64}
end

function Base.:<=(r1::RSPResource, r2::RSPResource)
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

function Base.min(r₁::RSPResource, r₂::RSPResource)
    new_c = min(r₁.c, r₂.c)
    new_w = min.(r₁.w, r₂.w)
    return RSPResource(new_c, new_w)
end

## Expansion functions

struct RSPForwardFunction
    c::Float64
    w::Vector{Float64}
end

function (f::RSPForwardFunction)(q::RSPResource; W)
    new_resource = RSPResource(f.c + q.c, f.w + q.w)
    return new_resource, all(new_resource.w .<= W)
end
struct RSPBackwardFunction
    c::Float64
    w::Vector{Float64}
end

function (f::RSPBackwardFunction)(q::RSPResource; W)
    new_resource = RSPResource(f.c + q.c, f.w + q.w)
    return new_resource
end

## Cost

struct RSPCost end
# W::Vector{Float64}

function (cost::RSPCost)(fr::RSPResource, br::RSPResource)
    return fr.c + br.c
end

# Wrapper

"""
$TYPEDSIGNATURES

Compute resource contrained shortest path between vertices `s` and `t` of graph `g`.

# Arguments
- `g::AbstractGraph`: acyclic directed graph.
- `max_costs::AbstractVector`: list of upper bounds for each resource constraint.
- `distmx::AbstractMatrix`: `distmx[i, j]` corresponds to the distance between vertices `i` and `j`
    along edge `(i, j)` of `g`.
- `costmx::Array{Float64, 3}`: `cost_mx[i, j, k]` corresponds to the resource cost of edge `(i, j)` for the `k`th resource constraint.

# Returns
- `p_star::Vector{Int}`: optimal path found.
- `c_star::Float64`: length of path `p_star`.
"""
function resource_shortest_path(
    graph::AbstractGraph{T},
    s::T,
    t::T,
    max_costs::AbstractVector,
    distmx::AbstractMatrix,
    costmx::Array{Float64,3},
) where {T}
    # origin forward resource and backward forward resource set to 0
    resource = RSPResource(0.0, zero(max_costs))

    # forward and backward expansion functions are equal
    If = [src(e) for e in edges(graph)]
    Jf = [dst(e) for e in edges(graph)]
    ff = [RSPForwardFunction(distmx[i, j], costmx[i, j, :]) for (i, j) in zip(If, Jf)]
    fb = [RSPBackwardFunction(distmx[i, j], costmx[i, j, :]) for (i, j) in zip(If, Jf)]
    FF = sparse(If, Jf, ff)
    FB = sparse(If, Jf, fb)

    instance = CSPInstance(;
        graph,
        origin_vertex=s,
        destination_vertex=t,
        origin_forward_resource=resource,
        destination_backward_resource=resource,
        cost_function=RSPCost(),
        forward_functions=FF,
        backward_functions=FB,
    )
    return generalized_constrained_shortest_path(instance; W=max_costs)
end
