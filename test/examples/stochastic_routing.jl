using ConstrainedShortestPaths
using Graphs
using SparseArrays
using JLD2

@testset "Path digraph" begin
    m = 5  # number of scenarios
    nb_vertices = 10

    graph = path_digraph(nb_vertices)
    nb_edges = ne(graph)
    I = [src(e) for e in edges(graph)]
    J = [dst(e) for e in edges(graph)]

    @testset "No delays" begin
        slacks = [[0.0] for _ in 1:nb_edges]
        slacks[end] = [Inf]
        intrinsic_delays = [0.0 for _ in 1:nb_vertices, _ in 1:m]
        slack_matrix = sparse(I, J, slacks)
        (; c_star, p_star) = stochastic_routing_shortest_path(
            graph, slack_matrix, intrinsic_delays
        )
        @test c_star == 0.0
        @test path_cost(p_star, slack_matrix, intrinsic_delays) == c_star
    end

    @testset "No slack" begin
        slacks = [[0.0] for _ in 1:nb_edges]
        slacks[end] = [Inf]
        intrinsic_delays = [0.0 for _ in 1:nb_vertices, _ in 1:m]
        intrinsic_delays[2, :] .= 1.0
        slack_matrix = sparse(I, J, slacks)
        (; c_star, p_star) = stochastic_routing_shortest_path(
            graph, slack_matrix, intrinsic_delays
        )
        @test c_star == 8
        @test path_cost(p_star, slack_matrix, intrinsic_delays) == c_star
    end

    @testset "With slack" begin
        slacks = [[1.0] for _ in 1:nb_edges]
        slacks[end] = [Inf]
        intrinsic_delays = [1.0 for _ in 1:nb_vertices, _ in 1:m]
        intrinsic_delays[1, :] .= 0.0
        intrinsic_delays[end, :] .= 0.0
        slack_matrix = sparse(I, J, slacks)
        (; c_star, p_star) = stochastic_routing_shortest_path(
            graph, slack_matrix, intrinsic_delays
        )
        @test c_star == 8
        @test path_cost(p_star, slack_matrix, intrinsic_delays) == c_star
    end

    @testset "With slack" begin
        slacks = [[1.0] for _ in 1:nb_edges]
        slacks[end] = [Inf]
        delays = [0.0 for _ in 1:nb_vertices, _ in 1:m]
        delays[2, :] .= 1.0
        slack_matrix = sparse(I, J, slacks)
        (; c_star, p_star) = stochastic_routing_shortest_path(graph, slack_matrix, delays)
        @test c_star == 1.0
        @test path_cost(p_star, slack_matrix, delays) == c_star
    end
end

@testset "Custom graph" begin
    m = 1

    nb_vertices = 5
    graph = SimpleDiGraph(nb_vertices)
    edge_list = [(1, 2), (1, 3), (2, 3), (2, 4), (3, 4), (4, 5)]
    for (i, j) in edge_list
        add_edge!(graph, i, j)
    end

    nb_edges = ne(graph)
    I = [src(e) for e in edges(graph)]
    J = [dst(e) for e in edges(graph)]
    λ = ones(nb_vertices)
    λ[1] = 0
    λ[end] = 0

    @testset "No delays" begin
        delays = reshape([0, 0, 0, 0, 0], nb_vertices, 1)
        slacks_theory = [[0.0] for _ in 1:nb_edges]
        slacks_theory[end] = [Inf]
        slack_matrix = sparse(I, J, slacks_theory)

        (; c_star, p_star) = stochastic_routing_shortest_path(graph, slack_matrix, delays)
        @test c_star == 0.0
        @test p_star == [1, 2, 4, 5]
        @test path_cost(p_star, slack_matrix, delays) == c_star

        (; c_star, p_star) = stochastic_routing_shortest_path(
            graph, slack_matrix, delays, λ
        )
        @test c_star == -3
        @test p_star == [1, 2, 3, 4, 5]
    end

    @testset "No slack" begin
        delays = reshape([0, 2, 1, 0, 0], nb_vertices, 1)
        slacks_theory = [[0.0] for _ in 1:nb_edges]
        slacks_theory[end] = [Inf]
        slack_matrix = sparse(I, J, slacks_theory)

        (; c_star, p_star) = stochastic_routing_shortest_path(graph, slack_matrix, delays)
        @test c_star == 2
        @test p_star == [1, 3, 4, 5]
        @test path_cost(p_star, slack_matrix, delays) == c_star

        (; c_star, p_star) = stochastic_routing_shortest_path(
            graph, slack_matrix, delays, λ
        )
        @test c_star == 0
        @test p_star == [1, 3, 4, 5]
    end

    @testset "With slack" begin
        delays = reshape([0, 3, 4, 0, 0], nb_vertices, 1)
        slacks_theory = [[0], [0], [0], [0], [3], [Inf]]
        slack_matrix = sparse(I, J, slacks_theory)
        (; c_star, p_star) = stochastic_routing_shortest_path(graph, slack_matrix, delays)
        @test c_star == 5
        @test p_star == [1, 3, 4, 5]
        @test path_cost(p_star, slack_matrix, delays) == c_star
    end

    # @testset "Detour with slack" begin
    #     delays = reshape([10, 1, 0, 0, 0], nb_vertices, 1)
    #     slacks_theory = [[5], [0], [5], [0], [0], [Inf]]
    #     slack_matrix = sparse(I, J, slacks_theory)
    #     (; c_star, p_star) = stochastic_routing_shortest_path(graph, slack_matrix, delays)
    #     @test c_star == 8
    #     @test p_star == [1, 2, 3, 4, 5]
    #     @test path_cost(p_star, slack_matrix, delays) == c_star
    # end
end

@testset "Random graphs" begin
    n = 5
    for nb_scenarios in 1:5
        for nb_vertices in 10:1:15
            for seed in 1:n
                rng = StableRNG(seed)
                graph = random_acyclic_digraph(
                    nb_vertices, rng; all_connected_to_source_and_destination=true
                )

                nb_edges = ne(graph)
                I = [src(e) for e in edges(graph)]
                J = [dst(e) for e in edges(graph)]

                delays = rand(rng, nb_vertices, nb_scenarios) * 10
                delays[1, :] .= 0.0
                delays[end, :] .= 0.0
                slacks_theory = [
                    if dst(e) == nb_vertices
                        [Inf for _ in 1:nb_scenarios]
                    else
                        [rand(rng) * 10 for _ in 1:nb_scenarios]
                    end for e in edges(graph)
                ]
                slack_matrix = sparse(I, J, slacks_theory)

                # Column generation using constrained shortest path algorithm, linear relaxation
                initial_paths = [[1, v, nb_vertices] for v in 2:(nb_vertices - 1)]
                λ_val, obj2, paths, dual, dual_new = stochastic_PLNE(
                    graph, slack_matrix, delays, initial_paths
                )
                _value, _obj2, _paths, _dual, _dual_new = stochastic_PLNE(
                    graph, slack_matrix, delays, initial_paths; bounding=false
                )
                @test obj2 ≈ _obj2
                # if !(obj2 ≈ _obj2)
                #     jldsave("debug.jld2"; graph, slack_matrix, delays, initial_paths)
                # end

                # Exact resolution
                obj, sol = solve_scenarios(graph, slack_matrix, delays)

                # Restricted master heuristic
                obj3, y3 = column_generation(
                    graph, slack_matrix, delays, cat(paths, initial_paths; dims=1)
                )

                @test obj ≈ obj2 || obj > obj2
                @test obj ≈ obj3 || obj3 > obj

                if !(obj ≈ obj2)
                    @info "Not equal" obj obj2 obj3
                end

                clow = obj2
                cupp = obj3
                threshold = cupp - clow
                if threshold > 0
                    additional_paths, costs = stochastic_routing_shortest_path_with_threshold(
                        graph, slack_matrix, delays, λ_val; threshold
                    )
                    full_paths = unique(vcat(initial_paths, paths, additional_paths))
                    obj4, y4 = column_generation(graph, slack_matrix, delays, full_paths)
                    @test obj4 ≈ cupp || obj4 < cupp
                    @test obj4 ≈ clow || obj4 > clow
                end
            end
        end
    end
end
