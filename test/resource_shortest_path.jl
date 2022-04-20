@testset "Custom example" begin
    nb_vertices = 4
    graph = MetaDiGraph(SimpleDiGraph(nb_vertices))

    edges = [(1, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
    costs = [1., 2., -1., 1., 1.]
    weights = [0., 0., 10., 0., 0]
    max_weight = 1.0

    forward_functions = Dict{Tuple{Int, Int}, CSPFunction}()
    backward_functions = Dict{Tuple{Int, Int}, CSPFunction}()

    for ((i, j), c, w) in zip(edges, costs, weights)
        add_edge!(graph, i, j)
        forward_functions[i, j] = CSPFunction(c, w)
        backward_functions[i, j] = CSPFunction(c, w)
        # set_prop!(graph, i, j, :forward_function, CSPFunction(c, w))
        # set_prop!(graph, i, j, :backward_function, CSPFunction(c, w))
    end

    origin_forward_resource = CSPResource(0., 0.)
    destination_backward_resource = CSPResource(0., 0.)

    instance = RCSPProblem(graph, origin_forward_resource, destination_backward_resource, CSPCost(max_weight), forward_functions, backward_functions)

    bounds = compute_bounds(instance)
    @info "Bounds" bounds
    initial_cost = instance.cost_function(origin_forward_resource, bounds[1])
    @info "Initial cost" initial_cost

    p_star, c_star = generalized_A_star(instance, bounds)
    @info "Shortest path" p_star
    @test c_star == 2
    @test initial_cost <= c_star
end
