using ConstrainedShortestPaths
const CSP = ConstrainedShortestPaths
using Graphs
using SparseArrays

m = 5
nb_vertices = 10

graph = path_digraph(nb_vertices)
nb_edges = ne(graph)
I = [src(e) for e in edges(graph)]
J = [dst(e) for e in edges(graph)]

@testset "No delays" begin
    slacks = [0.0 for _ in 1:nb_edges]
    delays = [0.0 for i in 1:nb_vertices, j in 1:m]
    slack_matrix = sparse(I, J, slacks)
    (; c_star, p_star) = stochastic_routing_shortest_path(graph, slack_matrix, delays)
    @test c_star == 0.0
end

@testset "No slack" begin
    slacks = [0.0 for _ in 1:nb_edges]
    delays = [1.0 for i in 1:nb_vertices, j in 1:m]
    slack_matrix = sparse(I, J, slacks)
    (; c_star, p_star) = stochastic_routing_shortest_path(graph, slack_matrix, delays)
    @test c_star == 45
end

@testset "With slack" begin
    slacks = [1.0 for _ in 1:nb_edges]
    delays = [1.0 for i in 1:nb_vertices, j in 1:m]
    slack_matrix = sparse(I, J, slacks)
    (; c_star, p_star) = stochastic_routing_shortest_path(graph, slack_matrix, delays)
    @test c_star == 9
end
