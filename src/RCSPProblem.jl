struct RCSPProblem{G<:MetaDiGraph,FR,BR,C}#,FF,BF}
    graph::G  # assumption : node 1 is origin, last node is destination
    origin_forward_resource::FR
    destination_backward_resource::BR
    cost_function::C
    #forward_functions::Vector{FF}
    #backward_functions::Vector{BF}
end

function is_dominated(rq::F, Mw::Vector{F}) where {F<:Any}
    for r in Mw
        if r <= rq
            return true
        end
    end
    return false
end
