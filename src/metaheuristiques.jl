function recuit_simule(A, k, T, heuristique, voisinage, mu, n_iter_max, log=false)
    # recuit simulé choix aléatoire voisin dans le voisinage considéré
    # les nombres de conflits sont calculés pour toute la solution à chaque itération, 
    # à modifier en calculant le cout incremental du voisin
    solution = heuristique(A, k) #solution initiale
    nb_conflit = n_conflit(A, solution)
    meilleure_solution = deepcopy(solution)
    nb_conflit_min = nb_conflit
    nb_conflit_initial = nb_conflit
    n_iter = 1
    while n_iter < n_iter_max
        if log 
            println("itération ", n_iter)
        end
        idx = rand(1:size(A)[1])
        voisin = voisinage(solution)[idx]
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

