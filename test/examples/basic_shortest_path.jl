@testset "Path digraph" begin
    nb_vertices = 10

    graph = path_digraph(nb_vertices)
    p_star, c_star = basic_shortest_path(graph, 1, nv(graph))
    @test c_star == nb_vertices - 1
    @test c_star == dijkstra_shortest_paths(graph, [1]).dists[end]
end

@testset "Simple example" begin
    nb_vertices = 4
    graph = SimpleDiGraph(nb_vertices)

    edge_list = [(1, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
    weight_list = [1.0, 2.0, -1.0, 1.0, 1.0]

    for (i, j) in edge_list
        add_edge!(graph, i, j)
    end

    Iw = [src(e) for e in edges(graph)]
    Jw = [dst(e) for e in edges(graph)]
    w = sparse(Iw, Jw, weight_list)

    p_star, c_star = basic_shortest_path(graph, 1, nv(graph), w)

    @test c_star == 1
end

@testset "Random graphs" begin
    n = 100
    nb_vertices = 30
    for i in 1:n
        Random.seed!(i)
        graph = random_acyclic_digraph(nb_vertices)

        weight_list = [rand() * 50 - 20 for _ in 1:ne(graph)]
        Iw = [src(e) for e in edges(graph)]
        Jw = [dst(e) for e in edges(graph)]
        w = sparse(Iw, Jw, weight_list, nb_vertices, nb_vertices)

        s = rand(1:(nb_vertices - 1))
        t = rand((s + 1):nb_vertices)

        p_star, c_star = basic_shortest_path(graph, s, t, w)
        p = enumerate_paths(bellman_ford_shortest_paths(graph, s, w), t)
        c = sum(w[p[i], p[i + 1]] for i in eachindex(p[1:(end - 1)]))
        @test c_star == c
        @test p_star == p
    end
end
