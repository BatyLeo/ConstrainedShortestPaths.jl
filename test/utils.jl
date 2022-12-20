function random_acyclic_digraph(
    nb_vertices::Integer; p=0.4, all_connected_to_source_and_destination=false
)
    edge_list = []
    for u in 1:nb_vertices
        if u < nb_vertices && !all_connected_to_source_and_destination
            push!(edge_list, (u, u + 1))
        end

        for v in (u + 1):(u == 1 ? nb_vertices - 1 : nb_vertices)
            if rand() <= p
                push!(edge_list, (u, v))
            end
        end
    end
    if all_connected_to_source_and_destination
        for i in 2:(nb_vertices - 1)
            push!(edge_list, (1, i))
            push!(edge_list, (i, nb_vertices))
        end
    end
    return SimpleDiGraph(Edge.(edge_list))
end

function resource_PLNE(g, d, c, C)
    model = Model(GLPK.Optimizer)

    nb_vertices = nv(g)
    nodes = 1:nb_vertices
    interior = 2:(nb_vertices - 1)

    @variable(model, y[i=nodes, j=nodes; has_edge(g, i, j)], Bin)

    @objective(model, Min, sum(d[src, dst] * y[src, dst] for (; src, dst) in edges(g)))

    @constraint(
        model,
        flow[i in interior],
        sum(y[j, i] for j in inneighbors(g, i)) == sum(y[i, j] for j in outneighbors(g, i))
    )
    @constraint(model, demand, sum(y[1, i] for i in outneighbors(g, 1)) == 1)
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

function path_cost(path, slacks, delays)
    nb_scenarios = size(delays, 2)
    old_v = path[1]
    R = delays[old_v, :]
    C = 0.0
    for v in path[2:(end - 1)]
        @. R = max(R - slacks[old_v, v], 0) + delays[v, :]
        C += sum(R) / nb_scenarios
        old_v = v
    end
    return C + vehicle_cost
end

function stochastic_PLNE(g, slacks, delays, initial_paths)
    nb_nodes = nv(g)
    job_indices = 2:(nb_nodes - 1)

    model = Model(GLPK.Optimizer)

    @variable(model, λ[v in 1:nb_nodes])

    @objective(model, Max, sum(λ[v] for v in job_indices))

    @constraint(
        model,
        con[p in initial_paths],
        path_cost(p, slacks, delays) - sum(λ[v] for v in job_indices if v in p) >= 0
    )
    @constraint(model, λ[1] == 0)
    @constraint(model, λ[nb_nodes] == 0)

    new_paths = Vector{Int}[]
    cons = []

    while true
        optimize!(model)
        λ_val = value.(λ)
        (; c_star, p_star) = stochastic_routing_shortest_path(g, slacks, delays, λ_val)
        full_cost =
            c_star + vehicle_cost + sum(λ_val[v] for v in job_indices if v in p_star)
        @assert path_cost(p_star, slacks, delays) + vehicle_cost ≈ full_cost
        if c_star + vehicle_cost > -eps
            break
        end
        push!(new_paths, p_star)
        push!(
            cons,
            @constraint(
                model, full_cost - sum(λ[v] for v in job_indices if v in p_star) >= 0
            )
        )
    end

    #@info "Dual Objective" dual_objective_value(model)

    return value.(λ), objective_value(model), new_paths, dual.(con), dual.(cons)
end

function column_generation(g, slacks, delays, paths::Vector{Vector{Int}}; bin=true)
    nb_nodes = nv(g)
    job_indices = 2:(nb_nodes - 1)

    model = Model(GLPK.Optimizer)

    if bin
        @variable(model, y[p in paths], Bin)
    else
        @variable(model, y[p in paths] >= 0)
    end

    @objective(model, Min, sum(path_cost(p, slacks, delays) * y[p] for p in paths))

    @constraint(model, con[v in job_indices], sum(y[p] for p in paths if v in p) == 1)

    optimize!(model)

    return objective_value(model), value.(y)
end

function solve_scenarios(graph, slacks, delays)
    nb_nodes = nv(graph)
    job_indices = 2:(nb_nodes - 1)
    nodes = 1:nb_nodes

    # Pre-processing
    ε = delays
    #Rmax = maximum(ε, dims=1)
    Rmax = maximum(sum(ε; dims=1))
    nb_scenarios = size(ε, 2)
    Ω = 1:nb_scenarios

    # Model definition
    model = Model(GLPK.Optimizer)
    #set_optimizer_attribute(model, "logLevel", 0)

    # Variables and objective function
    @variable(model, y[u in nodes, v in nodes; has_edge(graph, u, v)], Bin)
    @variable(model, R[v in nodes, ω in Ω] >= 0) # propagated delay of job v
    @variable(model, yR[u in nodes, v in nodes, ω in Ω; has_edge(graph, u, v)] >= 0) # yR[u, v] = y[u, v] * R[u, ω]

    @objective(
        model,
        Min,
        sum(sum(R[v, ω] for v in job_indices) for ω in Ω) / nb_scenarios # average total delay
            +
            vehicle_cost * sum(y[1, v] for v in job_indices) # nb_vehicles
    )

    # Flow contraints
    @constraint(
        model,
        flow[i in job_indices],
        sum(y[j, i] for j in inneighbors(graph, i)) ==
            sum(y[i, j] for j in outneighbors(graph, i))
    )
    @constraint(
        model,
        unit_demand[i in job_indices],
        sum(y[j, i] for j in inneighbors(graph, i)) == 1
    )

    # Delay propagation constraints
    @constraint(model, [ω in Ω], R[1, ω] == ε[1, ω])
    @constraint(model, R_delay_1[v in job_indices, ω in Ω], R[v, ω] >= ε[v, ω])
    @constraint(
        model,
        R_delay_2[v in job_indices, ω in Ω],
        R[v, ω] >=
            ε[v, ω] + sum(
            yR[u, v, ω] - y[u, v] * slacks[u, v][ω] for u in nodes if has_edge(graph, u, v)
        )
    )

    # Mc Cormick linearization constraints
    @constraint(
        model,
        R_McCormick_1[u in nodes, v in nodes, ω in Ω; has_edge(graph, u, v)],
        yR[u, v, ω] >= R[u, ω] + Rmax * (y[u, v] - 1)
    )
    @constraint(
        model,
        R_McCormick_2[u in nodes, v in nodes, ω in Ω; has_edge(graph, u, v)],
        yR[u, v, ω] <= Rmax * y[u, v]
    )

    # Solve model
    optimize!(model)
    solution = value.(y)

    paths = Vector{Int}[]
    for i in job_indices
        if solution[1, i] ≈ 1
            new_path = [1, i]
            index = i
            while index < nb_nodes
                for j in outneighbors(graph, index)
                    if solution[index, j] ≈ 1
                        push!(new_path, j)
                        index = j
                        break
                    end
                end
            end
            push!(paths, new_path)
        end
    end

    return objective_value(model), paths
end
