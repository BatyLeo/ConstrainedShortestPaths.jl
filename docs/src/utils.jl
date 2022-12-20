using Graphs, SparseArrays

function random_acyclic_digraph(nb_vertices::Integer; p=0.4)
    edge_list = []
    for u in 1:nb_vertices
        if u < nb_vertices
            push!(edge_list, (u, u + 1))
        end

        for v in (u + 2):nb_vertices
            if rand() <= p
                push!(edge_list, (u, v))
            end
        end
    end
    return SimpleDiGraph(Edge.(edge_list))
end
