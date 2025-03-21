@testset "Quality (Aqua.jl)" begin
    using Aqua
    Aqua.test_all(
        ConstrainedShortestPaths; ambiguities=false, deps_compat=(check_extras=false,)
    )
end

@testset "Correctness (JET.jl)" begin
    using JET
    JET.test_package(ConstrainedShortestPaths; target_modules=[ConstrainedShortestPaths])
end

@testset "Formatting (JuliaFormatter.jl)" begin
    using JuliaFormatter
    @test format(ConstrainedShortestPaths; verbose=false, overwrite=false)
end

@testset "Documenter" begin
    Documenter.doctest(ConstrainedShortestPaths)
end
