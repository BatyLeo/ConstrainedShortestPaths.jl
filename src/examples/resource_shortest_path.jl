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

# Wrapper

"""
    resource_shortest_path(g, s, t, distmx, costmx)

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
@traitfn function resource_shortest_path(
    g::G, max_costs::AbstractVector, s::T, t::T, distmx::AbstractMatrix, costmx::Array{Float64, 3}
) where {T, G <: AbstractGraph{T}; IsDirected{G}}
    # origin forward resource and backward forward resource set to 0
    resource = RSPResource(0., zero(max_costs))

    # forward and backward expansion functions are equal
    If = [src(e) for e in edges(g)]
    Jf = [dst(e) for e in edges(g)]
    f = [RSPFunction(distmx[i, j], costmx[i, j, :]) for (i, j) in zip(If, Jf)]
    F = sparse(If, Jf, f)

    instance = CSPInstance(g, resource, resource, RSPCost(max_costs), F, F)
    return generalized_constrained_shortest_path(instance, s, t)
end

"""
    resource_shortest_path(g, distmx, costmx)

Compute resource contrained shortest path between first and last vertices of graph `g`.

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
@traitfn function resource_shortest_path(
    g::G, max_costs::AbstractVector, distmx::AbstractMatrix, costmx::Array{Float64, 3}
) where {G <: AbstractGraph; IsDirected{G}}
    return resource_shortest_path(g, max_costs, 1, nv(g), distmx, costmx)
end
