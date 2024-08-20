abstract type AbstractCSPInstance end

"""
$TYPEDEF

# Fields
$TYPEDFIELDS
"""
struct CSPInstance{T,G<:AbstractGraph{T},FR,BR,C,FF<:AbstractMatrix,BF<:AbstractMatrix} <:
       AbstractCSPInstance
    "acyclic digraph in which to compute the shortest path"
    graph::G
    "origin vertex of path"
    origin_vertex::T
    "destination vertex of path"
    destination_vertex::T
    "forward resource at the origin vertex"
    origin_forward_resource::FR
    "backward resource at the destination vertex"
    destination_backward_resource::BR
    "cost function"
    cost_function::C
    "forward functions along edges"
    forward_functions::FF
    "backward functions along edges"
    backward_functions::BF
    "bit vector indicating if a vertices will be useful in the path computation, i.e. if there is a path from origin to destination that goes through it"
    is_useful::BitVector
    "precomputed topological ordering of useful vertices, from destination to source"
    topological_ordering::Vector{T}
end

"""
$TYPEDEF

# Fields
$TYPEDFIELDS
"""
struct ForwardCSPInstance{T,G<:AbstractGraph{T},FR,C,FF<:AbstractMatrix} <:
       AbstractCSPInstance
    "acyclic digraph in which to compute the shortest path"
    graph::G
    "origin vertex of path"
    origin_vertex::T
    "destination vertex of path"
    destination_vertex::T
    "forward resource at the origin vertex"
    origin_forward_resource::FR
    "cost function"
    cost_function::C
    "forward functions along edges"
    forward_functions::FF
    "bit vector indicating if a vertices will be useful in the path computation, i.e. if there is a path from origin to destination that goes through it"
    is_useful::BitVector
    "precomputed topological ordering of useful vertices, from destination to source"
    topological_ordering::Vector{T}
end

"""
$TYPEDSIGNATURES

Constructor for [`CSPInstance`](@ref).
"""
function CSPInstance(;
    graph,
    origin_vertex=1,
    destination_vertex=nv(graph),
    origin_forward_resource,
    destination_backward_resource=nothing,
    cost_function,
    forward_functions,
    backward_functions=nothing,
)
    @assert is_directed(graph) "`graph` must be a directed graph"
    @assert !is_cyclic(graph) "`graph` must be acyclic"
    useful_vertices = topological_order(graph, origin_vertex, destination_vertex)
    is_useful = falses(nv(graph))
    is_useful[useful_vertices] .= true
    if isnothing(destination_backward_resource) && isnothing(backward_functions)
        return ForwardCSPInstance(
            graph,
            origin_vertex,
            destination_vertex,
            origin_forward_resource,
            cost_function,
            forward_functions,
            is_useful,
            useful_vertices,
        )
    end
    # else
    return CSPInstance(
        graph,
        origin_vertex,
        destination_vertex,
        origin_forward_resource,
        destination_backward_resource,
        cost_function,
        forward_functions,
        backward_functions,
        is_useful,
        useful_vertices,
    )
end
