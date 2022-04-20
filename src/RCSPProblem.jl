struct RCSPProblem{G,FR,BR,C,FF,BF}
    graph::G  # assumption : node 1 is origin, last node is destination
    origin_forward_resource::FR
    destination_backward_resource::BR
    cost_function::C
    forward_functions::Dict{Tuple{Int, Int}, FF}
    backward_functions::Dict{Tuple{Int, Int}, BF}
end
