@testset "1D" begin
    nb_vertices = 4
    graph = SimpleDiGraph(nb_vertices)

    edge_list = [(1, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
    distance_list = [1., 2, -1., 1., 1.]
    costs_dimension = 1
    cost_list = [[0.], [0.], [10.], [0.], [0]]
    max_cost = [1.0]

    for (i, j) in edge_list
        add_edge!(graph, i, j)
    end

    I = [src(e) for e in edges(graph)]
    J = [dst(e) for e in edges(graph)]
    d = sparse(I, J, distance_list)

    c = [0. for i in 1:nb_vertices, j in 1:nb_vertices, k in 1:costs_dimension]
    for ((i, j), k) in zip(edge_list, cost_list)
        c[i, j, :] = k
    end

    p_star, c_star = resource_shortest_path(graph, max_cost, d, c)
    @test p_star == [1, 2, 4]
    @test c_star == 2
end

@testset "2D" begin
    nb_vertices = 4
    graph = SimpleDiGraph(nb_vertices)

    edge_list = [(1, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
    distance_list = [1., 0.5, -1., 1., 1.]
    costs_dimension = 2
    cost_list = [[0., 0.], [0., 10.], [10., 0.], [0., 0.], [0, 10.]]
    max_cost = [1.0, 1.0]

    for (i, j) in edge_list
        add_edge!(graph, i, j)
    end

    I = [src(e) for e in edges(graph)]
    J = [dst(e) for e in edges(graph)]
    d = sparse(I, J, distance_list)

    c = [0. for i in 1:nb_vertices, j in 1:nb_vertices, k in 1:costs_dimension]
    for ((i, j), k) in zip(edge_list, cost_list)
        c[i, j, :] = k
    end

    p_star, c_star = resource_shortest_path(graph, max_cost, d, c)
    @test p_star == [1, 2, 4]
    @test c_star == 2
end
