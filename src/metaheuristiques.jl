include("voisinages.jl")

function recuit_simule(A, k, T, heuristique, voisinage, mu, n_iter_max, log=false)
    # recuit simulé choix aléatoire voisin dans le voisinage considéré
    # les nombres de conflits sont calculés pour toute la solution à chaque itération, 
    # calculer le cout incremental plutot que le cout total n'ameliore pas le temps de résolution, au contraire, c est un peu plus long
    solution = heuristique(A, k) #solution initiale
    nb_conflit = n_conflit(A, solution)
    meilleure_solution = deepcopy(solution)
    nb_conflit_min = nb_conflit
    nb_conflit_initial = nb_conflit
    n_iter = 1
    while n_iter <= n_iter_max
        if log 
            println("itération ", n_iter)
        end
        voisin, avant_changements = voisinage(solution)
        nb_conflit_voisin = n_conflit(A, voisin)
        delta = nb_conflit_voisin - nb_conflit
        if log 
            println("nouveau voisin à une distance ",delta, " de la solution courante")
        end
        if delta < 0
            if log 
                println("solution courante améliorée à l'itération ", n_iter)
            end
            solution = voisin
            nb_conflit = nb_conflit_voisin
            if nb_conflit < nb_conflit_min
                if log 
                    println("meilleure solution améliorée à l'itération ", n_iter)
                end
                nb_conflit_min = nb_conflit
                meilleure_solution = voisin
            end
        else
            if log
                println("probabilité d'acceptation =  ",exp(-delta/T))
            end
            p = rand()
            if p < exp(-delta/T)
                if log 
                    println("solution dégradante acceptée à l'itération ",n_iter)
                    println("probabilité tirée =  ",p)
                end
                solution = voisin
                nb_conflit = nb_conflit_voisin
            end
        end
        T = mu*T
        n_iter += 1
    end
    return meilleure_solution, nb_conflit_initial, nb_conflit_min
end


function recherche_tabou(A, k, heuristique, voisinage, len_tabou, n_iter_max, log = false)
    # recherche tabou avec calcul du cout total, tester cout incremental mais a priori moins rapide
    # a tester : recherche tabou a voisinage variable : commencer par petits voisinages 
    # (dès que la solution est ameliorée on arrete de regarder ce voisinage)
    # a tester : len tabou variable en fonction du nombre d'itérations : commencer par grande puis diminuer 
    solution = heuristique(A, k) #solution initiale
    nb_conflit = n_conflit(A, solution)
    meilleure_solution = deepcopy(solution)
    nb_conflit_min = nb_conflit
    nb_conflit_initial = nb_conflit
    n_iter = 1
    n = size(A)[1] # nombre de sommets
    tabous = [[1 for couleur in 1:k] for sommet in 1:n] # TODO : modifier : tabous doit etre une matruce sommets * couleurs, une solution x est un dictionnaire s=>color
    while n_iter <= n_iter_max
        if log 
            println("itération ", n_iter)
        end
        voisins = voisinage(solution)
        tabou = true
        idx_voisin_1 = 0
        voisin_1 = nothing
        while tabou && idx_voisin_1 < n # premiere voisin non tabou
            idx_voisin_1 += 1
            voisin_1, _ = voisins[idx_voisin_1]
            tabou = prod([tabous[sommet][couleur] <= n_iter for (sommet, couleur) in voisin_1]) == false
        end
        nb_conflit_voisin_1 = n_conflit(A, voisin_1)
        for (voisin, _) in voisins
            nb_conflit_voisin = n_conflit(A,voisin)
            if prod([tabous[sommet][couleur] <= n_iter for (sommet, couleur) in voisin]) && nb_conflit_voisin < nb_conflit
                voisin_1 = voisin
                nb_conflit_voisin_1 = nb_conflit_voisin
            else
                if nb_conflit_voisin < nb_conflit_min
                    voisin_1 = voisin
                    nb_conflit_voisin_1 = nb_conflit_voisin
                    meilleure_solution = voisin
                    nb_conflit_min = nb_conflit_voisin
                end
            end
        end
        solution = voisin_1
        nb_conflit = nb_conflit_voisin_1
        if nb_conflit < nb_conflit_min
            meilleure_solution = solution
            nb_conflit_min = nb_conflit
        end
        for (sommet, couleur) in solution
            tabous[sommet][couleur] = n_iter + len_tabou
        end
        n_iter += 1
    end
    return meilleure_solution, nb_conflit_initial, nb_conflit_min
end