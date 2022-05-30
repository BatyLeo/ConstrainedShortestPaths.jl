```@meta
EditURL = "<unknown>/docs/src/literate/stochastic_vsp.jl"
```

# Stochastic Vehicle Scheduling

This kind application is the main reason this package was created in the first place.

## Problem definition

Vehicle Scheduling involves assigning vehicles to cover a set of scheduled tasks,
while minimizing a given objective function.

### Deterministic version

An instance of the problem is composed of:
- A set of tasks ``v\in\bar V``:
    - Scheduled task begin time: ``t_v^b``
    - Scheduled task end time: ``t_v^e (> t_v^b)``
    - Scheduled travel time from task ``u`` to task ``v``: ``t_{(u, v)}^{tr}``
- Task ``v`` can be scheduled after task ``u`` on a vehicle path only if: ``t_v^b \geq t_u^e + t_{(u, v)}^{tr}``
- Objective to minimize: number of vehicle used

This problem is very easy to solve using a compact MIP formulation.

### Stochastic version

The stochastic version is a variation that introduces random delays that occur after the
scheduling is fixed. The objective is now to minimize the expectation of the total delay.

We add the following to instances:
- Finite set of scenarios ``\Omega``.
- We indroduce three sets of random variables, which take different values depending on
    the scenario ``\omega\in\Omega``:
    - Intrisic delay of task ``v``: ``\varepsilon_v^\omega``
    - Slack between tasks ``u`` and ``v``: ``S_{uv}^\omega``
- Given an ``o-uv`` path ``P``, we define recursively the delay ``\Delta_v^\omega`` of task ``v`` in
    scenario ``\omega``  along ``P``:
```math
\boxed{\Delta_v^ω = ε_v^\omega + \max(\Delta_u^\omega - S_{u,v}^\omega, 0)}
```

- Objective to minimize: ``\dfrac{1}{|\Omega|}\sum\limits_{\omega\in\Omega} \Delta_v^\omega``

## Column generation formulation
We model an instance by the following acyclic Digraph ``D = (V, A)``:
- ``V = \bar V\cup \{o, d\}``, with ``o`` and ``d`` dummy origin and destination nodes
    connected to all tasks:
    - ``(o, v)`` arc for all task ``v\in \bar V``
    - ``(v, d)`` arc for all task ``v \in \bar V``
- There is an arc between tasks ``u`` and ``v`` only if ``t_v^b \geq t_u^e + t_{(u, v)}^{tr}``

A feasible vehicle tour is an ``o-d`` path ``P\in\mathcal P_{od}``. A feasible solution is a set
of disjoint feasible vehicle tours fulfilling all tasks exctly once.

Cost of a path ``P``: ``c_P = \dfrac{1}{|\Omega|}\sum\limits_{\omega\in\Omega}\sum\limits_{v\in V\backslash\{o,d\}}\Delta_v^\omega``

```math
\begin{aligned}
\min & \sum_{P\in\mathcal{P}}c_P y_P &\\
\text{s.t.} & \sum_{p\ni v} y_p = 1 &\forall v\in V\backslash\{o, d\} & \quad(\lambda_v\in\mathbb R)\\
& y_p\in\{0,1\} & \forall p\in \mathcal{P} &
\end{aligned}
```

This formulation can be solved using a column generation algorithm. The associated
subproblem is a constrained shortest path problem of the form :
```math
\boxed{\min_{P\in\mathcal P_{od}} \left\{c_P  - \sum_{v\in P}\lambda_v\right\}}
```

This subproblem can be solved using generalized constrained shortest paths algorithms
provided by this package.

## Using ConstrainedShortestPaths

````@example stochastic_vsp
using ConstrainedShortestPaths
using GLPK
using Graphs
using JuMP
using Random
using SparseArrays
````

### Create a random instance

Random graph acyclic directed graph

````@example stochastic_vsp
function random_acyclic_digraph(nb_vertices::Integer; p=0.4)
    edge_list = []
    for u in 1:nb_vertices
        for v in (u+1):(u == 1 ? nb_vertices-1 : nb_vertices)
            if rand() <= p
                push!(edge_list, (u, v))
            end
        end
    end
    for i in 2:nb_vertices-1
        push!(edge_list, (1, i))
        push!(edge_list, (i, nb_vertices))
    end
    return SimpleDiGraph(Edge.(edge_list))
end

Random.seed!(67)
nb_vertices = 30
nb_scenarios = 10
graph = random_acyclic_digraph(nb_vertices)
````

Random delays and slacks matrices:

````@example stochastic_vsp
nb_edges = ne(graph)
I = [src(e) for e in edges(graph)]
J = [dst(e) for e in edges(graph)]

delays = rand(nb_vertices, nb_scenarios) * 10
delays[end, :] .= 0.0
slacks = [dst(e) == nb_vertices ? [Inf for _ in 1:nb_scenarios] :
    [rand() * 10 for _ in 1:nb_scenarios] for e in edges(graph)]
slack_matrix = sparse(I, J, slacks);

# Path cost computation
function path_cost(path, slacks, delays)
    nb_scenarios = size(delays, 2)
    old_v = path[1]
    R = delays[old_v, :]
    C = 0.0
    for v in path[2:end-1]
        @. R = max(R - slacks[old_v, v], 0) + delays[v, :]
        C += sum(R) / nb_scenarios
        old_v = v
    end
    return C
end
````

## Column generation algorithm

We use the dual formulation with constraints generation:

````@example stochastic_vsp
function column_generation(g, slacks, delays)
    nb_vertices = nv(g)
    job_indices = 2:nb_vertices-1

    model = Model(GLPK.Optimizer)

    @variable(model, λ[v in 1:nb_vertices])

    @objective(model, Max, sum(λ[v] for v in job_indices))

    # Initialize constraints set with all [o, v, d] paths
    initial_paths = [[1, v, nb_vertices] for v in 2:nb_vertices-1]
    @constraint(
        model,
        con[p in initial_paths],
        path_cost(p, slacks, delays) - sum(λ[v] for v in job_indices if v in p) >= 0
    )
    @constraint(model, λ[1] == 0)
    @constraint(model, λ[nb_vertices] == 0)

    while true
        # Solve the master problem
        optimize!(model)
        λ_val = value.(λ)
        # Solve the shortest path subproblem
        (; c_star, p_star) = stochastic_routing_shortest_path(
            g, slacks, delays, λ_val
        )
        if c_star > -1e-10
            break
        end
        full_cost = c_star + sum(λ_val[v] for v in job_indices if v in p_star)
        # Add the most violated constraint
        @constraint(
            model,
            full_cost - sum(λ[v] for v in job_indices if v in p_star) >= 0
        )
    end

    return objective_value(model)
end

obj = column_generation(graph, slack_matrix, delays)
@info "Objective value" obj
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

