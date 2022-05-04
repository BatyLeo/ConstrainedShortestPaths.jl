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
    edge_list = [(1, 2), (2, 3), (2, 4), (3, 4)]
    for (i, j) in edge_list
        add_edge!(graph, i, j)
    end

    nb_edges = ne(graph)
    I = [src(e) for e in edges(graph)]
    J = [dst(e) for e in edges(graph)]

    @testset "No delays" begin
        slacks = [0.0 for _ in 1:nb_edges]
        delays = [0.0 for _ in 1:nb_vertices, _ in 1:m]
        slack_matrix = sparse(I, J, slacks)
        (; c_star, p_star) = stochastic_routing_shortest_path(graph, slack_matrix, delays)
        @test c_star == 0.0
        @test p_star == [1, 2, 4]
    end

    @testset "No slack" begin
        slacks = [0.0 for _ in 1:nb_edges]
        delays = [1.0 for _ in 1:nb_vertices, _ in 1:m]
        slack_matrix = sparse(I, J, slacks)
        (; c_star, p_star) = stochastic_routing_shortest_path(graph, slack_matrix, delays)
        @test c_star == 6
        @test p_star == [1, 2, 4]
    end

    @testset "With slack" begin
        slacks = [0.0, 5.0, 0.0, 5.0]
        delays = [1.0 for _ in 1:nb_vertices, _ in 1:m]
        slack_matrix = sparse(I, J, slacks)
        (; c_star, p_star) = stochastic_routing_shortest_path(graph, slack_matrix, delays)
        @test c_star == 5
        @test p_star == [1, 2, 3, 4]
    end

    @testset "With slack" begin
        slacks = [0.0, 0.0, 20.0, 0.0]
        delays = [1.0 for _ in 1:nb_vertices, _ in 1:m]
        slack_matrix = sparse(I, J, slacks)
        (; c_star, p_star) = stochastic_routing_shortest_path(graph, slack_matrix, delays)
        @test c_star == 4
        @test p_star == [1, 2, 4]
    end
end
