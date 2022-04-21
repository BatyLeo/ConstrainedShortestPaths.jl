using RCSP
using Test

using Graphs
using SparseArrays

@testset verbose=true "RCSP.jl" begin
    @testset "Basic Shortest Path" begin
        include("basic_shortest_path.jl")
    end

    @testset "Resource Shortest Path" begin
        include("resource_shortest_path.jl")
    end
end
