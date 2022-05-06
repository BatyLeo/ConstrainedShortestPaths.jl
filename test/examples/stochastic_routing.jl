using ConstrainedShortestPaths
using Graphs
using SparseArrays

@testset "Path digraph" begin
    m = 5
    nb_vertices = 10

    graph = path_digraph(nb_vertices)
    nb_edges = ne(graph)
    I = [src(e) for e in edges(graph)]
    J = [dst(e) for e in edges(graph)]

    @testset "No delays" begin
        slacks = [0.0 for _ in 1:nb_edges]
        delays = [0.0 for _ in 1:nb_vertices, _ in 1:m]
        slack_matrix = sparse(I, J, slacks)
        (; c_star, p_star) = stochastic_routing_shortest_path(graph, slack_matrix, delays)
        @test c_star == 0.0
    end

    @testset "No slack" begin
        slacks = [0.0 for _ in 1:nb_edges]
        delays = [1.0 for _ in 1:nb_vertices, _ in 1:m]
        slack_matrix = sparse(I, J, slacks)
        (; c_star, p_star) = stochastic_routing_shortest_path(graph, slack_matrix, delays)
        @test c_star == 55
    end

    @testset "With slack" begin
        slacks = [1.0 for _ in 1:nb_edges]
        delays = [1.0 for _ in 1:nb_vertices, _ in 1:m]
        slack_matrix = sparse(I, J, slacks)
        (; c_star, p_star) = stochastic_routing_shortest_path(graph, slack_matrix, delays)
        @test c_star == 10
    end
end

@testset "Custom graph" begin
    m = 1

    nb_vertices = 4
    graph = SimpleDiGraph(nb_vertices)
    edge_list = [(1, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
    for (i, j) in edge_list
        add_edge!(graph, i, j)
    end

    nb_edges = ne(graph)
    I = [src(e) for e in edges(graph)]
    J = [dst(e) for e in edges(graph)]

    @testset "No delays" begin
        delays = reshape([0, 0, 0, 0], nb_vertices, 1)
        slacks_theory = [0.0 for _ in 1:nb_edges]
        slacks = [s + delays[v] for ((u, v), s) in zip(edge_list, slacks_theory)]
        slack_matrix = sparse(I, J, slacks)
        (; c_star, p_star) = stochastic_routing_shortest_path(graph, slack_matrix, delays)
        @test c_star == 0.0
        @test p_star == [1, 2, 4]
    end

    @testset "No slack" begin
        delays = reshape([0, 2, 1, 0], nb_vertices, 1)
        slacks_theory = [0.0 for _ in 1:nb_edges]
        slacks = [s + delays[v] for ((u, v), s) in zip(edge_list, slacks_theory)]
        slack_matrix = sparse(I, J, slacks)
        (; c_star, p_star) = stochastic_routing_shortest_path(graph, slack_matrix, delays)
        @test c_star == 2
        @test p_star == [1, 3, 4]
    end

    @testset "With slack" begin
        delays = reshape([0, 3, 4, 0], nb_vertices, 1)
        slacks_theory = [0, 0, 0, 0, 3]
        slacks = [s + delays[v] for ((u, v), s) in zip(edge_list, slacks_theory)]
        slack_matrix = sparse(I, J, slacks)
        (; c_star, p_star) = stochastic_routing_shortest_path(graph, slack_matrix, delays)
        @test c_star == 5
        @test p_star == [1, 3, 4]
    end

    @testset "Detour with slack" begin
        delays = reshape([10, 1, 0, 0], nb_vertices, 1)
        slacks_theory = [5, 0, 5, 0, 0]
        slacks = [s + delays[v] for ((u, v), s) in zip(edge_list, slacks_theory)]
        slack_matrix = sparse(I, J, slacks)
        (; c_star, p_star) = stochastic_routing_shortest_path(graph, slack_matrix, delays)
        @test c_star == 15
        @test p_star == [1, 2, 3, 4]
    end
end

@testset "Random graphs one scenario" begin
    n = 100
    nb_vertices = 50
    m = 1
    for i in 1:n
        Random.seed!(i)
        graph = random_acyclic_digraph(nb_vertices)

        nb_edges = ne(graph)
        I = [src(e) for e in edges(graph)]
        J = [dst(e) for e in edges(graph)]

        delays = reshape([rand() * 10 for _ in 1:nb_vertices], nb_vertices, 1)
        slacks_theory = [rand() * 10 for _ in 1:nb_edges]
        slacks = [s + delays[e.dst] for (e, s) in zip(edges(graph), slacks_theory)]
        slack_matrix = sparse(I, J, slacks)
        (; c_star, p_star) = stochastic_routing_shortest_path(graph, slack_matrix, delays)

        c, p = stochastic_PLNE(graph, slack_matrix, delays)

        @test_broken c_star == c
        @test_broken p_star == p
    end
end
