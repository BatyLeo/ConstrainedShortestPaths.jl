m = 5
nb_vertices = 10

g = MetaDiGraph(path_digraph(nb_vertices))
nb_edges = ne(g)
slacks = [1.0 for _ in 1:nb_edges]
delays = [1.0 for i in 1:nb_vertices, j in 1:m]

origin_forward_resource = StochasticForwardResource(0.0, [0.0 for _ = 1:m])
destination_backward_resource = StochasticBackwardResource([R -> 0.0 for _ = 1:m])

forward_functions = Dict{Tuple{Int, Int}, StochasticForwardFunction}()
backward_functions = Dict{Tuple{Int, Int}, StochasticBackwardFunction}()

for (i, edge) in enumerate(edges(g))
    forward_functions[src(edge), dst(edge)] = StochasticForwardFunction(slacks[i], delays[i, :])
    backward_functions[src(edge), dst(edge)] = StochasticBackwardFunction(slacks[i], delays[i, :])
    # set_prop!(
    #     g,
    #     edge,
    #     :forward_function,
    #     StochasticForwardFunction(slacks[i], delays[i, :]),
    # )
    # set_prop!(
    #     g,
    #     edge,
    #     :backward_function,
    #     StochasticBackwardFunction(slacks[i], delays[i, :]),
    # )
end

instance = RCSPProblem(g, origin_forward_resource, destination_backward_resource, cost, forward_functions, backward_functions)

bounds = compute_bounds(instance)
#println(cost(origin_forward_resource, bounds[1]))
@test true
