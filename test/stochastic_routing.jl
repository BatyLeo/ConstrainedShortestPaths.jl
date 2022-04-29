using ConstrainedShortestPaths
const CSP = ConstrainedShortestPaths
using Graphs
using SparseArrays

m = 5
nb_vertices = 10

graph = path_digraph(nb_vertices)
nb_edges = ne(graph)
slacks = [0.0 for _ in 1:nb_edges]
delays = [1.0 for i in 1:nb_vertices, j in 1:m]

origin_forward_resource = CSP.StochasticForwardResource(0.0, [0.0 for _ = 1:m])
destination_backward_resource = CSP.StochasticBackwardResource([PiecewiseLinear(0.0, [0.0], [0.0]) for _ = 1:m])

ff = [CSP.StochasticForwardFunction(slacks[i], delays[i, :]) for i in 1:nb_edges]
bb = [CSP.StochasticBackwardFunction(slacks[i], delays[i, :]) for i in 1:nb_edges]

I = [src(e) for e in edges(graph)]
J = [dst(e) for e in edges(graph)]
FF = sparse(I, J, ff);
BB = sparse(I, J, bb);

instance = RCSPInstance(graph, origin_forward_resource, destination_backward_resource, CSP.stochastic_cost, FF, BB)

(; p_star, c_star) = generalized_constrained_shortest_path(instance)

@info "Solution found" p_star c_star
@test true
