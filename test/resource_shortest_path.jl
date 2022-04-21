nb_vertices = 4
graph = SimpleDiGraph(nb_vertices)

edge_list = [(1, 2), (1, 3), (2, 3), (2, 4), (3, 4)]
weight_list = [1., 2., -1., 1., 1.]
cost_list = [0., 0., 10., 0., 0]
max_cost = 1.0

for (i, j) in edge_list
    add_edge!(graph, i, j)
end

I = [src(e) for e in edges(graph)]
J = [dst(e) for e in edges(graph)]
w = sparse(I, J, weight_list)
c = sparse(I, J, cost_list)

p_star, c_star = resource_shortest_path(graph, max_cost, w, c)
@test c_star == 2
