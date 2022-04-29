f1 = PiecewiseLinear(1.0, [1], [0])
f2 = PiecewiseLinear(1.0, [5], [1])

# test intersection
@test intersection(f1, f2, 1, 0) == 2
@test intersection(f1, f2, 0, 0) == -1
@test intersection(f1, f2, 0, 1) == -1
@test intersection(f1, f2, 1, 1) == -1

# test composition
f3 = compose(f1, f2)
@test [f3(x) for x in 0:50] == [(f1 ∘ f2)(x) for x in 0:50]

# test meet operation
m = meet(f1, f2)
@test [m(x) for x in 0:50] == [min(f1(x), f2(x)) for x in 0:50]

# test sum
f4 = f1 + f2
@test [f4(x) for x in 0:50] == [f1(x) + f2(x) for x in 0:50]
