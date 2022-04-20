@testset "Path digraph" begin
    m = 5
    nb_vertices = 10

    g = MetaDiGraph(path_digraph(nb_vertices))
    nb_edges = ne(g)

    origin_forward_resource = 0.0
    destination_backward_resource = 0.0

    forward_functions = Dict{Tuple{Int, Int}, ShortestPathExpansionFunction}()
    backward_functions = Dict{Tuple{Int, Int}, ShortestPathExpansionFunction}()

    for (i, edge) in enumerate(edges(g))
        forward_functions[src(edge), dst(edge)] = ShortestPathExpansionFunction(1.0)
        backward_functions[src(edge), dst(edge)] = ShortestPathExpansionFunction(1.0)
    end

    instance = RCSPProblem(g, origin_forward_resource, destination_backward_resource, cost,
        forward_functions, backward_functions)

    bounds = compute_bounds(instance)
    @info "Bounds" bounds
    @info "Initial cost" cost(origin_forward_resource, bounds[1])

    p_star, c_star = generalized_A_star(instance, bounds)
    @info "Shortest path" p_star
    @test c_star == nb_vertices-1
end

@testset "Custom example" begin
    nb_vertices = 4
    graph = MetaDiGraph(SimpleDiGraph(nb_vertices))

    edges = [(1, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
    weights = [1., 2., -1., 1., 1.]

    forward_functions = Dict{Tuple{Int, Int}, ShortestPathExpansionFunction}()
    backward_functions = Dict{Tuple{Int, Int}, ShortestPathExpansionFunction}()
    for ((i, j), w) in zip(edges, weights)
        add_edge!(graph, i, j)
        forward_functions[i, j] = ShortestPathExpansionFunction(w)
        backward_functions[i, j] = ShortestPathExpansionFunction(w)
    end

    origin_forward_resource = 0.0
    destination_backward_resource = 0.0

    instance = RCSPProblem(graph, origin_forward_resource, destination_backward_resource, cost, forward_functions, backward_functions)

    bounds = compute_bounds(instance)
    @info "Bounds" bounds
    initial_cost = cost(origin_forward_resource, bounds[1])
    @info "Initial cost" initial_cost

    p_star, c_star = generalized_A_star(instance, bounds)
    @info "Shortest path" p_star
    @test c_star == 1
    @test initial_cost <= c_star
end
