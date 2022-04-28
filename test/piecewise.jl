using ConstrainedShortestPaths
using UnicodePlots
using Test

miniplot(f; points=0:20) = println(lineplot(points, [f(i) for i in points]))

f = PiecewiseLinear(1.0, [5, 10], [1, 50])
miniplot(f)

f1 = PiecewiseLinear(1.0, [1], [0])
miniplot(f1)
f2 = PiecewiseLinear(1.0, [5], [1])
miniplot(f2)
f3 = compose(f1, f2)
miniplot(f3)

@test [f3(x) for x in 0:50] == [(f1 ∘ f2)(x) for x in 0:50]

@test intersection(f1, f2, 1, 0) == 2
@test intersection(f1, f2, 0, 0) == -1
@test intersection(f1, f2, 0, 1) == -1
@test intersection(f1, f2, 1, 1) == -1

m = meet(f1, f2)

@test [m(x) for x in 0:50] == [min(f1(x), f2(x)) for x in 0:50]

meet(f1, m)

intersection(f1, m, 1, 1)
