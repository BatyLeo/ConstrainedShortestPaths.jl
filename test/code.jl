@testset "Quality (Aqua.jl)" begin
    using Aqua
    Aqua.test_all(
        ConstrainedShortestPaths; ambiguities=false, deps_compat=(check_extras=false,)
    )
end

@testset "Correctness (JET.jl)" begin
    using JET
    if VERSION >= v"1.8"
        JET.test_package(ConstrainedShortestPaths; toplevel_logger=nothing, mode=:typo)
    end
end

@testset "Formatting (JuliaFormatter.jl)" begin
    using JuliaFormatter
    @test format(ConstrainedShortestPaths; verbose=false, overwrite=false)
end

@testset "Documenter" begin
    Documenter.doctest(ConstrainedShortestPaths)
end
