function fplot(f, start=0, stop=15; name="f")
    ff(x) = f(x)
    println(lineplot(ff, start, stop; name=name))
end

function fplot_full(f_dict, start=0, stop=15)
    plt = nothing
    for (name, eff) in f_dict
        f(x) = eff(x)
        if isnothing(plt)
            plt = lineplot(f, start, stop; name=name)
        else
            lineplot!(plt, f, start, stop; name=name)
        end
    end
    println(plt)
end

@testset "Mini test" begin
    f1 = PiecewiseLinear(1.0, [1], [0])
    f2 = PiecewiseLinear(1.0, [5], [1])

    if SHOW_PLOTS
        fplot(f1)
        fplot(f2)
    end

    # test intersection
    @test intersection(f1, f2, 1, 0) == 2
    @test intersection(f1, f2, 0, 0) == -1
    @test intersection(f1, f2, 0, 1) == -1
    @test intersection(f1, f2, 1, 1) == -1

    # test composition
    f3 = compose(f1, f2)
    @test [f3(x) for x in 0:50] == [f1(f2(x)) for x in 0:50]

    # test meet operation
    m = meet(f1, f2)
    @test [m(x) for x in 0:50] == [min(f1(x), f2(x)) for x in 0:50]

    # test sum
    f4 = f1 + f2
    @test [f4(x) for x in 0:50] == [f1(x) + f2(x) for x in 0:50]
end

@testset "Mini test 2" begin
    f1 = PiecewiseLinear(1, [0], [0])
    f2 = PiecewiseLinear()

    if SHOW_PLOTS
        fplot(f1)
        fplot(f2)
    end

    # Test intersection
    @test intersection(f1, f2, 0, 0) == -1
    @test intersection(f1, f2, 1, 1) == -1

    # test meet operation
    m = meet(f1, f2)
    @test m.break_x == [0.] && m.break_y == [0.]
    @test [m(x) for x in 0:50] == [min(f1(x), f2(x)) for x in 0:50]

    # test sum
    f4 = f1 + f2
    @test [f4(x) for x in 0:50] == [f1(x) + f2(x) for x in 0:50]
end

@testset "Meet and sum" begin
    nb_tests = 100
    for i in 1:nb_tests
        Random.seed!(i)
        r(n=5, m=10) = sort([rand() * m for _ in 1:n])

        f1 = PiecewiseLinear(rand()*5, r(), r())
        f2 = PiecewiseLinear(rand()*5, r(), r())

        X = r(50, 50)
        f4 = meet(f1, f2)
        f5 = f1 + f2

        @test all([f4(x) for x in X] .≈ [min(f1(x), f2(x)) for x in X])
        @test all([f5(x) for x in X] .≈ [f1(x) + f2(x) for x in X])

        if SHOW_PLOTS
            fplot_full(Dict("f1" => f1, "f2" => f2))
            fplot_full(Dict("Meet" => f4))
            fplot_full(Dict("Sum" => f5))
        end
    end
end

@testset "Composition" begin
    nb_tests = 100
    for i in 1:nb_tests
        Random.seed!(i)
        r(m=10) = rand() * m

        f1 = PiecewiseLinear(1., [r()], [r()])
        f2 = PiecewiseLinear(1., [r()], [r()])
        f3 = compose(f1, f2)

        X = sort([r(50) for _ in 1:50])
        @test all([f3(x) for x in X] .≈ [f1(f2(x)) for x in X])

        if SHOW_PLOTS
            fplot_full(Dict("f1" => f1, "f2" => f2))
            fplot_full(Dict("Composition" => f3))
            fplot_full(Dict("theory" => x -> f1(f2(x))))
        end
    end
end
