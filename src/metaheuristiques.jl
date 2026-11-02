include("voisinages.jl")

function recuit_simule(adj, k, T, heuristique, voisinage, mu; limite_temps = 600, log=false)
    # recuit simulé choix aléatoire voisin dans le voisinage considéré
    # les nombres de conflits sont calculés pour toute la solution à chaque itération, 
    # calculer le cout incremental plutot que le cout total n'ameliore pas le temps de résolution, au contraire, c est un peu plus long
    avant_boucle = time()
    solution = heuristique(adj, k) #solution initiale
    nb_conflit = nb_conflits(solution,adj)
    meilleure_solution = deepcopy(solution)
    nb_conflit_min = nb_conflit
    nb_conflit_initial = nb_conflit
    n_iter = 1
    duree_resolution = time() - avant_boucle
    while duree_resolution < limite_temps
        debut_boucle = time()
        if nb_conflit_min == 0
            break
        end
        if log 
            println("Iter ", n_iter, "||conflits courants : ",nb_conflit,"||meilleurs conflits : ",nb_conflit_min, "||Temps : ", round(duree_resolution; digits = 2))
        end
        voisin, avant_changements = voisinage(solution)
        nb_conflit_voisin = nb_conflits(voisin,adj)
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
                nb_conflit_min = nb_conflit
                meilleure_solution = deepcopy(voisin)
                if log 
                    println("meilleure solution améliorée à l'itération ", n_iter)
                    println("cout de cette solution : ",nb_conflit_min)
                end
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
        duree_resolution += time() - debut_boucle
    end
    return meilleure_solution, nb_conflit_initial, nb_conflit_min, T, duree_resolution
end


function recherche_tabou(adj, n, k, heuristique, voisinage, len_tabou ; type_obj = "classique", taille_echantillon=5, taille_voisinage=5, n_iter_max_sans_amelioration=2500, n_perturbation_max_sans_amelioration = 3, limite_temps=600, log=false)
    taille_echantillon_initiale = taille_echantillon
    taille_voisinage_initiale = taille_voisinage
    avant_resolution = time()
    solution = heuristique(adj, k) # solution initiale
    meilleure_solution = deepcopy(solution)
    temps_meilleure_solution = time() - avant_resolution
    N_solutions = 0

    # C[u,c] = nombre de voisins de u de couleur c
    C = zeros(Int, n, k)
    for u in 1:n
        for v in adj[u]
            C[u, solution[v]] += 1
        end
    end

    # nombre de conflits par sommet
    conflits = [C[u, solution[u]] for u in 1:n]
    # Nombre total de conflits
    if type_obj == "classique"
        nb_conflit = sum(conflits) ÷ 2
    elseif type_obj == "pondéré"
        nb_conflit_reel = sum(conflits) ÷ 2
        nb_conflit = sum([conflits[u]^2 for u in 1:n]) # fonction objectif pour pénaliser les sommets ayant un grand nombre de conflits
    else
        error("type d'objectif non valide : $type_obj")
    end
    nb_conflit_initial = nb_conflit
    nb_conflit_min = nb_conflit
    if log
        println("nombre de conflits initial : ", nb_conflit_initial)
        if type_obj == "pondéré"
            println("nombre de conflits réels initial : ", nb_conflit_reel)
        end
    end

    # Ensemble des sommets en conflit
    # on utilise 2 listes pour que les tests d'appartenance d'un sommet aux sommets en conflits soient en O(1)
    sommets_avec_conflits = Int[]
    positions = zeros(Int, n)
    for u in 1:n
        if conflits[u] > 0
            ajouter_conflit(sommets_avec_conflits, positions, u)
        end
    end

    tabous = ones(Int, n, k)
    n_iter = 1
    n_iter_sans_amelioration = 0
    n_perturbation_sans_amelioration = -1
    duree_resolution = time() - avant_resolution

    # boucle principale
    while duree_resolution < limite_temps
        debut_boucle = time()
        if nb_conflit_min == 0
            break
        end
        if isempty(sommets_avec_conflits) || k <= 1
            break
        end
        if log
            println("Iter ", n_iter, "||conflits courants : ", nb_conflit, 
            "||meilleurs conflits : ", nb_conflit_min, "||nb iter sans amélioration : ", n_iter_sans_amelioration, "||Temps : ", round(duree_resolution; digits = 2))
        end
        if n_iter_sans_amelioration > n_iter_max_sans_amelioration
            if log
                println("Aucune amélioration depuis ",n_iter_max_sans_amelioration," itérations : phase de perturbation forcée.")
            end
            n_iter_sans_amelioration = 0
            n_perturbation_sans_amelioration += 1
            if n_perturbation_sans_amelioration % n_perturbation_max_sans_amelioration == 0 && n_perturbation_sans_amelioration > 0
                if log
                    println("Aucune amélioration depuis ",n_perturbation_max_sans_amelioration," perturbations forcée : on agrandit la taille du voisinage exploré.")
                end
                taille_echantillon = min(30, taille_echantillon + 5)
                taille_voisinage = min(30, taille_voisinage + 5)
            end
            solution, _ = voisinage(solution, k, taille_voisinage)
            p = rand()
            if p<0.5
                solution, _ = voisinage(meilleure_solution, k, taille_voisinage)
            else
                solution, _ = voisinage(solution, k, taille_voisinage)
            end    

            fill!(C, 0)
            for u in 1:n
                for v in adj[u]
                    C[u, solution[v]] += 1
                end
            end

            for u in 1:n
                conflits[u] = C[u, solution[u]]
            end
            if type_obj == "classique"
                nb_conflit = sum(conflits) ÷ 2
            else
                nb_conflit = sum([conflits[u]^2 for u in 1:n]) # fonction objectif pour pénaliser les sommets ayant un grand nombre de conflits
            end

            empty!(sommets_avec_conflits)
            fill!(positions, 0)
            for u in 1:n
                if conflits[u] > 0
                    ajouter_conflit(sommets_avec_conflits, positions, u)
                end
            end

            fill!(tabous, 1)
        end

        # compromis entre explorer tout le voisinage (tres couteux) et 
        #choisir un sommet avec conflits et la meilleure couleur pour ce sommet :
        # compromis entre les 2 : meilleur voisin parmi les taille_echantillon sommets avec conflits
        nb_sommets_avec_conflits = length(sommets_avec_conflits)
        taille_echantillon_effectif = min(taille_echantillon, nb_sommets_avec_conflits)
        indices = Set{Int}()
        while length(indices) < taille_echantillon_effectif
            push!(indices, rand(1:nb_sommets_avec_conflits)) # indices est un set donc tous les indices seront distincts, on n'aura pas 2 fois le meme sommet sans conflit
        end
        sommets_choisis = [sommets_avec_conflits[i] for i in indices]

        meilleur_delta = typemax(Int)
        meilleur_sommet = nothing
        meilleure_couleur = nothing
        meilleur_delta_global = typemax(Int)
        meilleur_sommet_global = nothing
        meilleure_couleur_globale = nothing

        for u in sommets_choisis
            ancienne_couleur = solution[u]
            if type_obj == "classique"
                cout_actuel = C[u, ancienne_couleur]
            end
            for c in 1:k
                if c == ancienne_couleur
                    continue
                end
                if type_obj == "classique"
                    delta = C[u,c] - cout_actuel
                else
                    delta = C[u, c]^2 - C[u, ancienne_couleur]^2
                    for v in adj[u]
                        conflits_v = conflits[v]
                        conflits_v_apres = conflits_v + Int(solution[v]==c) - Int(solution[v]==ancienne_couleur)
                        delta += conflits_v_apres^2 - conflits_v^2
                    end
                end
                # Meilleur mouvement, même s'il est tabou (utile dans le cas ou tous les voisins sont tabous)
                if delta < meilleur_delta_global
                    meilleur_delta_global = delta
                    meilleur_sommet_global = u
                    meilleure_couleur_globale = c
                end

                tabou = tabous[u,c] > n_iter
                aspiration = nb_conflit + delta < nb_conflit_min
                if (!tabou || aspiration) && delta < meilleur_delta
                    meilleur_delta = delta
                    meilleur_sommet = u
                    meilleure_couleur = c
                end
            end
        end

        if meilleur_sommet == nothing
            if log
                println("Aucun voisin non tabou dans le voisinage : on va choisir le meilleur voisin (même si tabou)")
            end
            meilleur_sommet = meilleur_sommet_global
            meilleure_couleur = meilleure_couleur_globale
            meilleur_delta = meilleur_delta_global
        end
        u = meilleur_sommet
        ancienne_couleur = solution[u]
        nouvelle_couleur = meilleure_couleur

        # on met a jour les nombres de conflits
        nb_conflit += meilleur_delta
        for v in adj[u]
            conflits[v] += Int(solution[v] == nouvelle_couleur) - Int(solution[v] == ancienne_couleur)
            C[v, ancienne_couleur] -= 1
            C[v, nouvelle_couleur] += 1
            if conflits[v] > 0
                ajouter_conflit(sommets_avec_conflits, positions, v)
            else
                retirer_conflit(sommets_avec_conflits, positions, v)
            end
        end

        solution[u] = nouvelle_couleur
        conflits[u] = C[u, nouvelle_couleur]
        if conflits[u] == 0
            retirer_conflit(sommets_avec_conflits, positions, u)
        end
        
        if nb_conflit < nb_conflit_min
            temps_meilleure_solution = time() - avant_resolution
            meilleure_solution = deepcopy(solution)
            nb_conflit_min = nb_conflit
            if log
                println("Nouvelle meilleure solution : ", nb_conflit_min)
            end
            n_iter_sans_amelioration = 0
            n_perturbation_sans_amelioration = 0
            taille_echantillon = taille_echantillon_initiale # on repart d'un voisinage de taille plus restreinte
            taille_voisinage = taille_voisinage_initiale
        else 
            n_iter_sans_amelioration += 1
        end

        len_tabou = div(0.6*nb_conflit_min + rand(0:9),1) # mis à jour dynamique de len_tabou
        if log
            println("len tabou = ", len_tabou)
        end
        tabous[u, ancienne_couleur] = n_iter + len_tabou
        n_iter += 1
        duree_resolution += time() - debut_boucle
        N_solutions += taille_echantillon_effectif * (k-1) # nombre de solution explorées à chaque itération
    end
    vitesse_exploration = N_solutions/duree_resolution
    return meilleure_solution, nb_conflit_initial, nb_conflit_min, duree_resolution, temps_meilleure_solution, vitesse_exploration
end