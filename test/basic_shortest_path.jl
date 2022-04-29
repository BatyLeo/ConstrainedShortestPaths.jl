@testset "Path digraph" begin
    nb_vertices = 10

    graph = path_digraph(nb_vertices)
    p_star, c_star = basic_shortest_path(graph)
    @test c_star == nb_vertices-1
    @test c_star == dijkstra_shortest_paths(graph, [1]).dists[end]
end

@testset "Simple example" begin
    nb_vertices = 4
    graph = SimpleDiGraph(nb_vertices)

    edge_list = [(1, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
    weight_list = [1., 2., -1., 1., 1.]

    for (i, j) in edge_list
        add_edge!(graph, i, j)
    end

    Iw = [src(e) for e in edges(graph)]
    Jw = [dst(e) for e in edges(graph)]
    w = sparse(Iw, Jw, weight_list)

    p_star, c_star = basic_shortest_path(graph, w)

    @test c_star == 1
end
