"""
Only increasing functions
"""
struct PiecewiseLinear
    final_slope::Int
    break_x::Vector{Float64}
    break_y::Vector{Float64}
end

PiecewiseLinear(final_slope::Int, x::Float64, y::Float64) =
    PiecewiseLinear(final_slope, [x], [y])

"""
    closest_break_point(f, x)

Find the index of the closest break point from x
(at its right i fright=true else at its left)
"""
function closest_break_point(f::PiecewiseLinear, x::Real; right=true)
    break_x = f.break_x
    nb_break_points = length(break_x)

    for (i, x̄) in enumerate(break_x)
        if x <= x̄
            return right ? i : i-1
        end
    end
    return right ? nb_break_points + 1 : nb_break_points
end

function (f::PiecewiseLinear)(x::Real)
    break_x, break_y = f.break_x, f.break_y
    nb_break_points = length(break_x)
    closest = closest_break_point(f, x)

    if closest == 1 # x is before first break point
        return break_y[1]
    end
    if closest == nb_break_points + 1 # x is after last break point
        return break_y[end] + f.final_slope * (x - break_x[end])
    end
    # else, x is between two breakpoints
    y1, y2 = break_y[closest-1], break_y[closest]
    x1, x2 = break_x[closest-1], break_x[closest]
    slope = (y2 - y1) / (x2 - x1)
    return y1 + slope * (x - x1)
end

"""
    f1 ∘ f2

! only support functions with only one break point and final slope 1
"""
function compose(f1::PiecewiseLinear, f2::PiecewiseLinear)
    # ! only support functions with only one break point and final slope 1
    x1, y1 = f1.break_x[1], f1.break_y[1]
    x2, y2 = f2.break_x[1], f2.break_y[1]
    new_x = x1 + max(x2 - y2, 0)
    new_y = y1 + max(y2 - x2, 0)
    return PiecewiseLinear(1., [new_x], [new_y])
end

function get_x(f::PiecewiseLinear, i::Int; x_max=1000)
    return i <= length(f.break_x) ? f.break_x[i] : x_max
end

function get_y(f::PiecewiseLinear, i::Int; x_max=1000)
    return i <= length(f.break_y) ? f.break_y[i] : f(x_max)
end

function get_points(f1::PiecewiseLinear, f2::PiecewiseLinear, i1::Int, i2)
    n1 = length(f1.break_x)
    n2 = length(f2.break_x)
    x_min = min(f1.break_x[1], f2.break_x[1]) - 1
    x_max = max(f1.break_x[end], f2.break_x[end]) + 1

    x1, y1, x2, y2 = 0., 0., 0., 0.

    if i1 == 0
        x1, y1 = x_min, f1(x_min)
    elseif i1 > n1
        x1, y1 = x_max, f1(x_max)
    else
        x1, y1 = f1.break_x[i1], f1.break_y[i1]
    end

    if i2 == 0
        x2, y2 = x_min, f2(x_min)
    elseif i2 > n2
        x2, y2 = x_max, f2(x_max)
    else
        x2, y2 = f2.break_x[i2], f2.break_y[i2]
    end

    return x1, y1, x2, y2
end

"""
return -1 if there is no intersection else the x of intersection
"""
function intersection(f1::PiecewiseLinear, f2::PiecewiseLinear, i1::Int, i2::Int)
    no_intersection = -1.0

    x11, y11, x21, y21 = get_points(f1, f2, i1, i2)
    x12, y12, x22, y22 = get_points(f1, f2, i1+1, i2+1)

    # @info "Points" x11 y11 x12 y12 x21 y21 x22 y22

    if x12 < x21 || x22 < x11
        return no_intersection
    end

    xi1 = max(x11, x21)
    xi2 = min(x12, x22)
    if sign(f1(xi1) - f2(xi1)) == sign(f1(xi2) - f2(xi2))
        return no_intersection
    end
    # else, there is an intersection
    a1 = (y12 - y11) / (x12 - x11)
    b1 = y11 - a1 * x11
    a2 = (y22 - y21) / (x22 - x21)
    b2 = y21 - a2 * x21
    return (b2 - b1) / (a1 - a2)
end

"""
minimum of two piecewise linear functions
"""
function meet(f1::PiecewiseLinear, f2::PiecewiseLinear)
    final_slope = min(f1.final_slope, f2.final_slope)
    x_list = Float64[]
    y_list = Float64[]

    i1 = 0
    i2 = 0

    i1_max = length(f1.break_x)
    i2_max = length(f2.break_x)
    while i1 < i1_max || i2 < i2_max
        i1 = min(i1, i1_max)
        i2 = min(i2, i2_max)
        x = intersection(f1, f2, i1, i2)
        if x == -1
            # advance the function advancing less
            x1 = get_x(f1, i1 + 1)
            x2 = get_x(f2, i2 + 1)
            if x1 < x2
                i1 += 1
                y1, y2 = f1(x1), f2(x1)
                if y1 <= y2
                    push!(x_list, x1)
                    push!(y_list, y1)
                end
            elseif x1 > x2
                i2 += 1
                y1, y2 = f1(x2), f2(x2)
                if y2 <= y1
                    push!(x_list, x2)
                    push!(y_list, y2)
                end
            else # if x1 == x2
                i1 += 1
                i2 += 1
                x = get_x(f1, i1)
                y = min(f1(x), f2(x))
                push!(x_list, x)
                push!(y_list, y)
            end
        else  # if there is an intersection
            # add intersection
            push!(x_list, x)
            push!(y_list, f1(x)) # = f2(x)
            # advance the function advancing less
            x1 = get_x(f1, i1 + 1)
            x2 = get_x(f2, i2 + 1)
            if x1 < x2
                i1 += 1
                y11, y21 = f1(x1), f2(x1)
                y22 = f2(x2)
                if y11 <= y21 && y11 <= y22
                    push!(x_list, x1)
                    push!(y_list, y11)
                elseif y11 >= y21 && y11 >= y22
                    push!(x_list, x2)
                    push!(y_list, y22)
                end
            elseif x1 > x2
                i2 += 1
                y12, y22 = f1(x2), f2(x2)
                y21 = f1(x1)
                if y22 <= y12 && y22 <= y21
                    push!(x_list, x2)
                    push!(y_list, y22)
                elseif y22 >= y12 && y22 >= y21
                    push!(x_list, x1)
                    push!(y_list, y21)
                end
            else # if x1 == x2
                i1 += 1
                i2 += 1
                x = get_x(f1, i1)
                y = min(f1(x), f2(x))
                push!(x_list, x)
                push!(y_list, y)
            end
        end
    end

    return PiecewiseLinear(final_slope, x_list, y_list)
end
