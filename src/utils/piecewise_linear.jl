"""
    PiecewiseLinear

Type used to represent increasing piecewise linear functions, with starting slope 0.

# Attributes
- `final_slope::Float64`: (positive) slope of the last linear piece.
- `break_x::Vector{Float64}`: (ordered) list of all break points x-coordinates.
- `break_y::Vector{Float64}`: (non decreasing) list of all break points y-coordinates
    corresponding to `break_x` elementwise.
"""
struct PiecewiseLinear
    final_slope::Float64
    break_x::Vector{Float64}
    break_y::Vector{Float64}
end

function PiecewiseLinear(final_slope::Float64, slack::Float64, delay::Float64)
    if slack == Inf
        return PiecewiseLinear(0.0, [0.0], [delay])
    end
    return PiecewiseLinear(final_slope, [slack], [delay])
end

PiecewiseLinear() = PiecewiseLinear(0.0, 0.0, 0.0)

"""
    closest_break_point(break_x, x)

Find the index of the closest break point from x.
(at its right i fright=true else at its left)
"""
function closest_break_point(break_x::AbstractVector, x::Real; right=true)
    nb_break_points = length(break_x)

    for (i, x̄) in enumerate(break_x)
        if x <= x̄
            return right ? i : i-1
        end
    end
    return right ? nb_break_points + 1 : nb_break_points
end

"""
    (f)(x)

Returns f(x).
"""
function (f::PiecewiseLinear)(x::Real)
    break_x, break_y = f.break_x, f.break_y
    nb_break_points = length(break_x)
    closest = closest_break_point(break_x, x)

    if closest == 1 # x is before first break point
        return break_y[1]
    elseif closest == nb_break_points + 1 # x is after last break point
        return break_y[end] + f.final_slope * (x - break_x[end])
    end
    # else, x is between two breakpoints
    y1, y2 = break_y[closest-1], break_y[closest]
    x1, x2 = break_x[closest-1], break_x[closest]
    # slope = (y2 - y1) / (x2 - x1)
    return y1 + (y2 - y1) * (x - x1) / (x2 - x1)
end

# TODO: remove this workaround
function my_push!(v::AbstractVector, element)
    if element[end] != v
        push!(v, element)
    end
    return nothing
end

"""
    +(f1, f2)

Return a PiecewiseLinear corresponding to f1 + f2.
"""
function +(f1::PiecewiseLinear, f2::PiecewiseLinear)
    #x_list_base = sort(unique(cat(f1.break_x, f2.break_x; dims=1)))
    slope = f1.final_slope + f2.final_slope

    x_list = Float64[]
    i2_max = length(f2.break_x)
    i1_max = length(f1.break_x)
    i1, i2 = 1, 1
    x_max = max(maximum(f1.break_x), maximum(f2.break_x)) + 10
    while i1 <= i1_max || i2 <= i2_max
        x1 = get_x(f1, i1; x_max=x_max)
        x2 = get_x(f2, i2; x_max=x_max)
        if x1 < x2
            my_push!(x_list, x1)
            i1 += 1
        elseif x1 > x2
            my_push!(x_list, x2)
            i2 += 1
        else # if x1 == x2
            my_push!(x_list, x1)
            i1 += 1
            i2 += 1
        end
    end

    y_list = [f1(x) + f2(x) for x in x_list] # TODO: optimizable
    return PiecewiseLinear(slope, x_list, y_list)
end

"""
    compose(f1, f2)

Return a PiecewiseLinear corresponding to f1 ∘ f2
! only support functions with only one break point and final slope 1
"""
function compose(f1::PiecewiseLinear, f2::PiecewiseLinear)
    x_list = Float64[]
    y_list = Float64[]
    for (i, x1) in enumerate(f2.break_x)
        x2 = get_x(f2, i+1)
        y1, y2 = f2(x1), f2(x2)
        my_push!(x_list, x1)
        my_push!(y_list, f1(y1))
        a = (y2 - y1) / (x2 - x1)
        if a == 0
            continue
        end
        b = y1 - a * x1
        jmin = closest_break_point(f1.break_x, y1; right=true)
        jmax = closest_break_point(f1.break_x, y2; right=false)
        for j in jmin:jmax
            x̄ = f1.break_x[j]
            x = (x̄ - b) / a
            my_push!(x_list, x)
            my_push!(y_list, f1(x̄))
        end
    end
    return PiecewiseLinear(f1.final_slope * f2.final_slope, x_list, y_list)

    # # ! only support functions with only one break point and final slope 1
    # if f1.final_slope == 0.0
    #     return PiecewiseLinear()
    # end
    # x1, y1 = f1.break_x[1], f1.break_y[1]
    # x2, y2 = f2.break_x[1], f2.break_y[1]
    # new_x = x2 + max(x1 - y2, 0)
    # new_y = y1 + max(y2 - x1, 0)
    # return PiecewiseLinear(1., [new_x], [new_y])
end

"""
    get_x(f, i; x_max=1000)

Return x coordinate of break_point i. If i is out of range, return x_max
"""
function get_x(f::PiecewiseLinear, i::Int; x_max=1000)
    return i <= length(f.break_x) ? f.break_x[i] : x_max
end

# !!! not used
# """
#     get_y(f, i; x_max=1000)

# Return y coordinate of break_point i. If i is out of range, return f(x_max)
# """
# function get_y(f::PiecewiseLinear, i::Int; x_max=1000)
#     return i <= length(f.break_y) ? f.break_y[i] : f(x_max)
# end

"""
    get_points(f1, f2, i1, i2)

Return break point i1 of f1 and break point i2 of f2. If i1 or i2 are out of range,
return a border (x, f(x)).
"""
function get_points(f1::PiecewiseLinear, f2::PiecewiseLinear, i1::Int, i2::Int; delta=1000)
    n1 = length(f1.break_x)
    n2 = length(f2.break_x)
    x_min = min(f1.break_x[1], f2.break_x[1]) - delta
    x_max = max(f1.break_x[end], f2.break_x[end]) + delta

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
    intersection(f1, f2, i1, i2)

Return -1 if there is no intersection else the x coordinate of the intersection.
"""
function intersection(f1::PiecewiseLinear, f2::PiecewiseLinear, i1::Int, i2::Int)
    no_intersection = -1.0

    x11, y11, x21, y21 = get_points(f1, f2, i1, i2)
    x12, y12, x22, y22 = get_points(f1, f2, i1+1, i2+1)

    if x12 < x21 || x22 < x11  # intervals do not intersect
        return no_intersection
    end

    # TODO: check edge cases
    xi1 = max(x11, x21)
    xi2 = min(x12, x22)
    signi1 = sign(f1(xi1) - f2(xi1))
    signi2 = sign(f1(xi2) - f2(xi2))
    if signi1 * signi2 >= 0  # == 0 || signi2 == 0 || signi1 == signi2
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
    meet(f1, f2)

Compute the minimum of two PiecewiseLinear functions
Return a PiecewiseLinear f, such that ∀x, f(x) = min(f1(x), f2(x)).
"""
function meet(f1::PiecewiseLinear, f2::PiecewiseLinear)
    if (f1.break_x == [0.0] && f1.break_x == [0.0]) || (f2.break_y == [0.0] && f2.break_y == [0.0])
        # ! doesn't work when negative
        return PiecewiseLinear()
    end
    # TODO: check edge cases
    final_slope = min(f1.final_slope, f2.final_slope)
    x_list = Float64[]
    y_list = Float64[]

    i1 = 0
    i2 = 0

    x_max = max(maximum(f1.break_x), maximum(f2.break_x)) + 10
    i1_max = length(f1.break_x)
    i2_max = length(f2.break_x)
    while i1 < i1_max || i2 < i2_max
        #@warn "i" i1 i2 i1_max i2_max f1 f2
        i1 = min(i1, i1_max)
        i2 = min(i2, i2_max)
        x = intersection(f1, f2, i1, i2)
        if x == -1
            # advance the function advancing less
            x1 = get_x(f1, i1 + 1; x_max=x_max)
            x2 = get_x(f2, i2 + 1; x_max=x_max)
            if x1 < x2
                i1 += 1
                y1, y2 = f1(x1), f2(x1)
                if y1 < y2
                    my_push!(x_list, x1)
                    my_push!(y_list, y1)
                end
            elseif x1 > x2
                i2 += 1
                y1, y2 = f1(x2), f2(x2)
                if y2 < y1
                    my_push!(x_list, x2)
                    my_push!(y_list, y2)
                end
            else # if x1 == x2
                i1 += 1
                i2 += 1
                x = get_x(f1, i1; x_max=x_max)
                y = min(f1(x), f2(x))
                my_push!(x_list, x)
                my_push!(y_list, y)
            end
        else  # if there is an intersection
            # add intersection
            my_push!(x_list, x)
            my_push!(y_list, f1(x)) # = f2(x)
            # advance the function advancing less
            x1 = get_x(f1, i1 + 1; x_max=x_max)
            x2 = get_x(f2, i2 + 1; x_max=x_max)
            if x1 < x2
                i1 += 1
                y11, y21 = f1(x1), f2(x1)
                y22 = f2(x2)
                if y11 <= y21 && y11 <= y22 && x != x1
                    my_push!(x_list, x1)
                    my_push!(y_list, y11)
                elseif y11 >= y21 && y11 >= y22 && x != x1
                    i2 += 1
                    my_push!(x_list, x2)
                    my_push!(y_list, y22)
                end
            elseif x1 > x2
                i2 += 1
                y12, y22 = f1(x2), f2(x2)
                y21 = f1(x1)
                if y22 <= y12 && y22 <= y21 && x != x1
                    my_push!(x_list, x2)
                    my_push!(y_list, y22)
                elseif y22 >= y12 && y22 >= y21 && x != x1
                    i1 += 1
                    my_push!(x_list, x1)
                    my_push!(y_list, y21)
                end
            else # if x1 == x2
                i1 += 1
                i2 += 1

                x1 = get_x(f1, i1; x_max=x_max)
                if x1 != x
                    y = min(f1(x), f2(x))
                    my_push!(x_list, x)
                    my_push!(y_list, y)
                end
            end
        end
    end
    #@warn "Lists" x_list y_list i1 i2

    x = intersection(f1, f2, i1_max, i2_max)
    if x != -1
        my_push!(x_list, x)
        my_push!(y_list, f1(x))
    end

    if x_list == []
        @warn "Empty return" f1 f2
    end

    return PiecewiseLinear(final_slope, x_list, y_list)
end
