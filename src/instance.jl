struct RCSPInstance{G,FR,BR,C,FF<:AbstractMatrix,BF<:AbstractMatrix}
    graph::G  # assumption : node 1 is origin, last node is destination
    origin_forward_resource::FR
    destination_backward_resource::BR
    cost_function::C
    forward_functions::FF #Dict{Tuple{Int, Int}, FF}
    backward_functions::BF  #Dict{Tuple{Int, Int}, BF}
end
