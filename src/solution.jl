function n_conflit(A, solution)
    # fonction évaluant le nombre de conflit d'une solution
    N = 0
    n = size(A)[1]
    for u in 1:(n-1)
        for v in u+1:n 
            if A[u,v] ==1 && (solution[u]==solution[v])
                N += 1
            end
        end
    end
    return N
end

function increment_n_conflit(A, avant_changements, apres_changements, solution)
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
            if apres_changements[u] == solution[v] # si v dans apres changements on a quand meme apres_changements[v]=solution[v]
                nb_conflit_final += 1
            end
        end
    end
    delta = nb_conflit_final - nb_conflit_initial
    return delta          
end
    