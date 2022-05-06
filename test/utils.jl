function random_acyclic_digraph(nb_vertices::Integer; p=0.4)
    edge_list = []
    for u in 1:nb_vertices
        if u < nb_vertices
            push!(edge_list, (u, u+1))
        end

        for v in (u+2):nb_vertices
            if rand() <= p
                push!(edge_list, (u, v))
            end
        end
    end
    return SimpleDiGraph(Edge.(edge_list))
end

function resource_PLNE(g, d, c, C)
    model = Model(GLPK.Optimizer)

    nb_vertices = nv(g)
    nodes = 1:nb_vertices
    interior = 2:nb_vertices-1

    @variable(model, y[i=nodes, j=nodes; has_edge(g, i, j)], Bin)

    @objective(model, Min, sum(d[src, dst] * y[src, dst] for (;src, dst) in edges(g)))

    @constraint(
        model,
        flow[i in interior],
        sum(y[j, i] for j in inneighbors(g, i)) ==
        sum(y[i, j] for j in outneighbors(g, i))
    )
    @constraint(
        model,
        demand,
        sum(y[1, i] for i in outneighbors(g, 1)) == 1
    )
    @constraint(
        model,
        resource[k in 1:length(C)],
        sum(c[src, dst, k] * y[src, dst] for (; src, dst) in edges(g)) <= C[k]
    )

    optimize!(model)

    solution = value.(y)

    i = 1
    p = [1]
    while i < nb_vertices
        for j in outneighbors(g, i)
            if solution[i, j] ≈ 1
                i = j
                push!(p, j)
                break
            end
        end
    end

    return objective_value(model), p
end

function stochastic_PLNE(g, slacks, delays)
    model = Model(GLPK.Optimizer)

    # TODO

    return 0, []
end
