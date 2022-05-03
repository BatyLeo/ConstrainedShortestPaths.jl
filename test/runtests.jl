using ConstrainedShortestPaths
using Test

using Graphs
using Random
using SparseArrays
using UnicodePlots

const SHOW_PLOTS = false

@testset verbose=true "RCSP.jl" begin
    @testset "PiecewiseLinear" begin
        include("piecewise_linear.jl")
    end

    @testset "Examples" verbose=true begin
        @testset "Basic Shortest Path" begin
            include("examples/basic_shortest_path.jl")
        end

        @testset "Resource Shortest Path" begin
            include("examples/resource_shortest_path.jl")
        end

        @testset "Stochastic routing" begin
            include("examples/stochastic_routing.jl")
        end
    end
end
