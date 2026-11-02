# nombre d'arêtes en conflit (même couleur aux 2 extrémités)
function nb_conflits(solution, adj::Vector{Vector{Int}})
    conflits = 0
    for u in 1:length(solution)
        for v in adj[u]
            if u < v && solution[u] == solution[v]
                conflits += 1
            end
        end
    end
    return conflits
end

function objectif_pondere(solution, adj)
    # C[u,c] = nombre de voisins de u de couleur c
    C = zeros(Int, n, k)
    for u in 1:n
        for v in adj[u]
            C[u, solution[v]] += 1
        end
    end
    return sum([C[u, solution[u]]^2 for u in 1:n])
end

function increment_n_conflit(A, adj, solution, avant_changements)
    nb_conflit_initial = 0
    nb_conflit_final = 0
    for u in keys(avant_changements) # memes sommets pour avant et apres, seules les valeurs du dictionnaire (couleurs) changent
        for v in adj[u]
            if v in keys(avant_changements)
                if avant_changements[u] == avant_changements[v]
                    nb_conflit_initial += 1
                end
            else
                if avant_changements[u] == solution[v]
                    nb_conflit_initial += 1
                end
            end
            if solution[u] == solution[v] 
                nb_conflit_final += 1
            end
        end
    end
    delta = nb_conflit_final - nb_conflit_initial
    return delta          
end

function ajouter_conflit(sommets, positions, u)
    #ajouter un nouveau sommet aux sommets ayant au moins un conflit
    if positions[u] == 0
        push!(sommets, u)
        positions[u] = length(sommets)
    end
end

function retirer_conflit(sommets, positions, u)
    #retirer un sommet parmi ceux ayant au moins un conflit
    idx = positions[u]
    if idx != 0
        dernier = sommets[end]
        sommets[idx] = dernier
        positions[dernier] = idx
        pop!(sommets)
        positions[u] = 0
    end
end
    

# détection des sommets en conflit (pour cibler les recherches)
function get_sommets_en_conflit(solution, adj)
    conflicts = Int[]
    for u in 1:length(solution)
        for v in adj[u]
            if solution[u] == solution[v]
                push!(conflicts, u)
                break # On ne compte ce sommet qu'une seule fois
            end
        end
    end
    return conflicts
end
