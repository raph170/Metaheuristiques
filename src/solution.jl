function n_conflit(A, solution)
    # fonction évaluant le nombre total de conflits d'une solution et le nombre de conflits par sommet 
    n = size(A)[1]
    N_conflit_total = 0
    N_conflit_par_sommet = Dict(u => 0 for u in 1:n)
    for u in 1:(n-1)
        for v in u+1:n 
            if A[u,v] ==1 && (solution[u]==solution[v])
                N_conflit_total += 1
                N_conflit_par_sommet[u] += 1
            end
        end
    end
    return N_conflit_total, N_conflit_par_sommet
end

function increment_n_conflit(A, solution, avant_changements)
    nb_conflit_initial = 0
    nb_conflit_final = 0
    voisins = liste_voisins(A)
    for u in keys(avant_changements) # memes sommets pour avant et apres, seules les valeurs du dictionnaire (couleurs) changent
        for v in voisins[u]
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
    

