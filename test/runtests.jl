using RCSP
using Test

using Graphs, MetaGraphs

@testset verbose=true "RCSP.jl" begin
    @testset "Shortest Path" begin
        include("shortest_path.jl")
    end
    
    @testset "Resource Constrained Shortest Path" begin
        include("resource_shortest_path.jl")
    end

    @testset "Stochastic routing" begin
        #include("stochastic_routing.jl")
    end
end
