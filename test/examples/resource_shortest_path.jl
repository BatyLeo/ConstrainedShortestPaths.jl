@testset "1D" begin
    nb_vertices = 4
    graph = SimpleDiGraph(nb_vertices)

    edge_list = [(1, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
    distance_list = [1.0, 2, -1.0, 1.0, 1.0]
    costs_dimension = 1
    cost_list = [[0.0], [0.0], [10.0], [0.0], [0]]
    max_cost = [1.0]

    for (i, j) in edge_list
        add_edge!(graph, i, j)
    end

    I = [src(e) for e in edges(graph)]
    J = [dst(e) for e in edges(graph)]
    d = sparse(I, J, distance_list)

    c = [0.0 for i in 1:nb_vertices, j in 1:nb_vertices, k in 1:costs_dimension]
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
    distance_list = [1.0, 0.5, -1.0, 1.0, 1.0]
    costs_dimension = 2
    cost_list = [[0.0, 0.0], [0.0, 10.0], [10.0, 0.0], [0.0, 0.0], [0, 10.0]]
    max_cost = [1.0, 1.0]

    for (i, j) in edge_list
        add_edge!(graph, i, j)
    end

    I = [src(e) for e in edges(graph)]
    J = [dst(e) for e in edges(graph)]
    d = sparse(I, J, distance_list)

    c = [0.0 for i in 1:nb_vertices, j in 1:nb_vertices, k in 1:costs_dimension]
    for ((i, j), k) in zip(edge_list, cost_list)
        c[i, j, :] = k
    end

    p_star, c_star = resource_shortest_path(graph, max_cost, d, c)
    @test p_star == [1, 2, 4]
    @test c_star == 2
end

@testset "Random graphs" begin
    n = 100
    nb_vertices = 50
    costs_dimension = 2
    for i in 1:n
        Random.seed!(i)
        graph = random_acyclic_digraph(nb_vertices)

        distance_list = [rand() * 20 - 5 for _ in 1:ne(graph)]
        Iw = [src(e) for e in edges(graph)]
        Jw = [dst(e) for e in edges(graph)]
        d = sparse(Iw, Jw, distance_list, nb_vertices, nb_vertices)

        cost_list = []
        for e in edges(graph)
            if (e.dst == e.src + 1)
                push!(cost_list, [0.0 for _ in 1:costs_dimension])
            else
                push!(cost_list, [rand() * 10 for _ in 1:costs_dimension])
            end
        end
        max_cost = [10.0, 10.0]
        c = [0.0 for i in 1:nb_vertices, j in 1:nb_vertices, k in 1:costs_dimension]
        for (e, k) in zip(edges(graph), cost_list)
            c[e.src, e.dst, :] = k
        end

        p_star, c_star = resource_shortest_path(graph, max_cost, d, c)
        c, p = resource_PLNE(graph, d, c, max_cost)
        @test c_star ≈ c
        @test p_star == p
    end
end
