
using Random

# Recherche du meilleur mouvement dans le voisinage V_2 (2-color ciblé sur les sommets en conflit et leurs voisins)
function meilleur_mvt_2_color(solution, adj, couleurs, sommets_conf; sommets_visites=Set{Int}(), autoriser_plateau=false)
    meilleur_delta = 0
    meilleur_u = -1
    meilleur_v = -1
    meilleure_cu = -1
    meilleure_cv = -1
    nb_meilleurs = 0
    
    mvt_neutre_trouve = false
    neutre_u = -1
    neutre_v = -1
    neutre_cu = -1
    neutre_cv = -1
    nb_neutres = 0
    
    max_c = maximum(couleurs)
    freq_u = zeros(Int, max_c)
    freq_v = zeros(Int, max_c)
    
    # Échantillonnage sur les grands graphes denses
    nb_conf = length(sommets_conf)
    u_candidats = (nb_conf > 40) ? [sommets_conf[i] for i in randperm(nb_conf)[1:40]] : sommets_conf

    for u in u_candidats
        c_u_orig = solution[u]
        
        deg_u = length(adj[u])
        v_candidats = (deg_u > 50) ? [adj[u][i] for i in randperm(deg_u)[1:50]] : adj[u]
        
        for v in v_candidats
            c_v_orig = solution[v]
            
            # Fréquence des couleurs chez les voisins de u (hors v)
            fill!(freq_u, 0)
            for w in adj[u]
                if w != v
                    col_w = solution[w]
                    if col_w > 0 && col_w <= max_c
                        freq_u[col_w] += 1
                    end
                end
            end
            
            # Fréquence des couleurs chez les voisins de v (hors u)
            fill!(freq_v, 0)
            for w in adj[v]
                if w != u
                    col_w = solution[w]
                    if col_w > 0 && col_w <= max_c
                        freq_v[col_w] += 1
                    end
                end
            end
            
            was_conflict = (c_u_orig == c_v_orig) ? 1 : 0
            
            # Cas 1 : (u, v) est l'arête en conflit -> u et v changent de couleur (cu != cv)
            if was_conflict == 1
                if u < v # Évite d'évaluer la paire {u, v} deux fois
                    for cu in couleurs
                        delta_u = freq_u[cu] - freq_u[c_u_orig]
                        if delta_u <= 1 # Filtrage : tester uniquement les couleurs prometteuses pour u
                            for cv in couleurs
                                if cu != cv
                                    delta_v = freq_v[cv] - freq_v[c_v_orig]
                                    delta_total = delta_u + delta_v - 1 # Résolution du conflit de l'arête (u, v)
                                    
                                    if delta_total < meilleur_delta
                                        meilleur_delta = delta_total
                                        meilleur_u = u
                                        meilleur_v = v
                                        meilleure_cu = cu
                                        meilleure_cv = cv
                                        nb_meilleurs = 1
                                    elseif delta_total == meilleur_delta && delta_total < 0
                                        nb_meilleurs += 1
                                        if rand() < (1.0 / nb_meilleurs)
                                            meilleur_u = u
                                            meilleur_v = v
                                            meilleure_cu = cu
                                            meilleure_cv = cv
                                        end
                                    elseif autoriser_plateau && delta_total == 0 && meilleur_delta == 0
                                        # Mouvement neutre sans cycle : ni u ni v ne doivent être déjà visités sur ce plateau
                                        if !(u in sommets_visites) && !(v in sommets_visites)
                                            nb_neutres += 1
                                            if rand() < (1.0 / nb_neutres)
                                                mvt_neutre_trouve = true
                                                neutre_u = u
                                                neutre_v = v
                                                neutre_cu = cu
                                                neutre_cv = cv
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            else
                # Cas 2 : u prend la couleur de v (cu = c_v_orig), et v libère cette couleur vers cv
                cu = c_v_orig
                delta_u = freq_u[cu] - freq_u[c_u_orig]
                
                for cv in couleurs
                    if cv != cu && cv != c_v_orig
                        delta_v = freq_v[cv] - freq_v[c_v_orig]
                        delta_total = delta_u + delta_v
                        
                        if delta_total < meilleur_delta
                            meilleur_delta = delta_total
                            meilleur_u = u
                            meilleur_v = v
                            meilleure_cu = cu
                            meilleure_cv = cv
                            nb_meilleurs = 1
                        elseif delta_total == meilleur_delta && delta_total < 0
                            nb_meilleurs += 1
                            if rand() < (1.0 / nb_meilleurs)
                                meilleur_u = u
                                meilleur_v = v
                                meilleure_cu = cu
                                meilleure_cv = cv
                            end
                        elseif autoriser_plateau && delta_total == 0 && meilleur_delta == 0
                            # Mouvement neutre sans cycle
                            if !(u in sommets_visites) && !(v in sommets_visites)
                                nb_neutres += 1
                                if rand() < (1.0 / nb_neutres)
                                    mvt_neutre_trouve = true
                                    neutre_u = u
                                    neutre_v = v
                                    neutre_cu = cu
                                    neutre_cv = cv
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    if meilleur_delta < 0
        return meilleur_delta, meilleur_u, meilleur_v, meilleure_cu, meilleure_cv
    elseif mvt_neutre_trouve
        return 0, neutre_u, neutre_v, neutre_cu, neutre_cv
    else
        return 0, -1, -1, -1, -1
    end
end

# Descente à Voisinage Variable (VND) : V_1 (1-color) puis V_2 (2-color)
function descente_VND(solution, adj, couleurs; max_iter=500, max_plateau=25, eval_counter=nothing, type_obj="classique")
    sol_courante = copy(solution)
    max_c = maximum(couleurs)
    n = length(sol_courante)
    
    is_pondere = (type_obj == "pondéré")
    conflits_par_sommet = is_pondere ? [count(v -> sol_courante[v] == sol_courante[u], adj[u]) for u in 1:n] : Int[]
    somme_voisins_ponderee = is_pondere ? zeros(Int, max_c) : Int[]
    score_courant = is_pondere ? sum(conflits_par_sommet[u]^2 for u in 1:n) : nb_conflits(sol_courante, adj)
    
    iter = 0
    plateau_count = 0
    sommets_parcourus_plateau = Set{Int}() # les sommets modifiés sur ce plateau (pour éviter les cycles)
    freq_couleurs = zeros(Int, max_c)
    
    k_vnd = 1 # Ordre du voisinage de descente : 1 = 1-color, 2 = 2-color
    a_utilise_v2 = false
    
    while score_courant > 0 && iter < max_iter
        iter += 1
        
        # On teste les sommets qui posent un problème
        sommets_conf = get_sommets_en_conflit(sol_courante, adj)
        if isempty(sommets_conf)
            break
        end
        
        # Stratégie Best Improvement : recherche du meilleur mouvement (s*, c*) sur tout le voisinage
        if k_vnd == 1
            if eval_counter !== nothing
                eval_counter[] += length(sommets_conf) * (length(couleurs) - 1)
            end
            # Voisinage V_1 : 1-color
            meilleur_delta = 0
            meilleur_s = -1
            meilleur_c = -1
            nb_meilleurs = 0
            
            mvt_neutre_trouve = false
            sommet_neutre = -1
            couleur_neutre = -1
            nb_neutres = 0
            
            for s in sommets_conf
                c_orig = sol_courante[s]
                
                # Comptage des couleurs chez les voisins de s
                fill!(freq_couleurs, 0)
                somme_perte_orig = 0
                if is_pondere
                    fill!(somme_voisins_ponderee, 0)
                    for v in adj[s]
                        col_v = sol_courante[v]
                        if col_v > 0 && col_v <= max_c
                            freq_couleurs[col_v] += 1
                            somme_voisins_ponderee[col_v] += 2 * conflits_par_sommet[v] + 1
                            if col_v == c_orig
                                somme_perte_orig += -2 * conflits_par_sommet[v] + 1
                            end
                        end
                    end
                else
                    for v in adj[s]
                        col_v = sol_courante[v]
                        if col_v > 0 && col_v <= max_c
                            freq_couleurs[col_v] += 1
                        end
                    end
                end
                conflits_actuels_de_s = freq_couleurs[c_orig]
                
                for c in couleurs
                    if c != c_orig
                        if is_pondere
                            # Variation quadratique sur s et ses voisins : delta de sum (conflits[u])^2
                            delta = (freq_couleurs[c]^2 - conflits_actuels_de_s^2) + somme_perte_orig + somme_voisins_ponderee[c]
                        else
                            # (conflits créés avec c) - (conflits supprimés de c_orig)
                            delta = freq_couleurs[c] - conflits_actuels_de_s
                        end
                        
                        if delta < meilleur_delta
                            meilleur_delta = delta
                            meilleur_s = s
                            meilleur_c = c
                            nb_meilleurs = 1
                        elseif delta == meilleur_delta && delta < 0
                            # Départage aléatoire équitable en cas d'égalité sur la meilleure amélioration
                            nb_meilleurs += 1
                            if rand() < (1.0 / nb_meilleurs)
                                meilleur_s = s
                                meilleur_c = c
                            end
                        elseif delta == 0 && meilleur_delta == 0 && plateau_count < max_plateau
                            # Mouvement neutre sur plateau si le sommet n'a pas déjà été visité (anti-cycle)
                            if !(s in sommets_parcourus_plateau)
                                nb_neutres += 1
                                if rand() < (1.0 / nb_neutres)
                                    mvt_neutre_trouve = true
                                    sommet_neutre = s
                                    couleur_neutre = c
                                end
                            end
                        end
                    end
                end
            end
            
            # On applique le meilleur mouvement trouvé sur tout le voisinage V_1
            if meilleur_delta < 0
                c_old = sol_courante[meilleur_s]
                sol_courante[meilleur_s] = meilleur_c
                if is_pondere
                    for v in adj[meilleur_s]
                        if sol_courante[v] == c_old
                            conflits_par_sommet[v] -= 1
                        elseif sol_courante[v] == meilleur_c
                            conflits_par_sommet[v] += 1
                        end
                    end
                    conflits_par_sommet[meilleur_s] = count(v -> sol_courante[v] == meilleur_c, adj[meilleur_s])
                    score_courant = sum(conflits_par_sommet[u]^2 for u in 1:n)
                else
                    score_courant += meilleur_delta
                end
                plateau_count = 0 # Reset du plateau après une amélioration
                empty!(sommets_parcourus_plateau)
                k_vnd = 1 # Reste dans V_1
            elseif mvt_neutre_trouve && plateau_count < max_plateau
                # Mouvement neutre pour naviguer sur le plateau
                c_old = sol_courante[sommet_neutre]
                sol_courante[sommet_neutre] = couleur_neutre
                if is_pondere
                    for v in adj[sommet_neutre]
                        if sol_courante[v] == c_old
                            conflits_par_sommet[v] -= 1
                        elseif sol_courante[v] == couleur_neutre
                            conflits_par_sommet[v] += 1
                        end
                    end
                    conflits_par_sommet[sommet_neutre] = count(v -> sol_courante[v] == couleur_neutre, adj[sommet_neutre])
                    score_courant = sum(conflits_par_sommet[u]^2 for u in 1:n)
                end
                push!(sommets_parcourus_plateau, sommet_neutre) # On verrouille ce sommet pour ce plateau
                plateau_count += 1
            else
                # Bloqué dans V_1 -> on essaie le voisinage V_2 (2-color)
                k_vnd = 2
            end
            
        elseif k_vnd == 2
            # Voisinage V_2 : 2-color
            delta_2, u, v, cu, cv = meilleur_mvt_2_color(sol_courante, adj, couleurs, sommets_conf;
                                                          sommets_visites=sommets_parcourus_plateau,
                                                          autoriser_plateau=(plateau_count < max_plateau))
            
            if delta_2 < 0
                a_utilise_v2 = true
                # Amélioration trouvée dans V_2 : on applique les 2 changements
                sol_courante[u] = cu
                sol_courante[v] = cv
                if is_pondere
                    for node in 1:n
                        conflits_par_sommet[node] = count(w -> sol_courante[w] == sol_courante[node], adj[node])
                    end
                    score_courant = sum(conflits_par_sommet[node]^2 for node in 1:n)
                else
                    score_courant = nb_conflits(sol_courante, adj)
                end
                plateau_count = 0
                empty!(sommets_parcourus_plateau)
                k_vnd = 1 # retour au voisinage V_1
            elseif delta_2 == 0 && u != -1 && plateau_count < max_plateau
                # Mouvement neutre en 2-color pour naviguer sur le plateau (anti-cycle)
                sol_courante[u] = cu
                sol_courante[v] = cv
                if is_pondere
                    for node in 1:n
                        conflits_par_sommet[node] = count(w -> sol_courante[w] == sol_courante[node], adj[node])
                    end
                    score_courant = sum(conflits_par_sommet[node]^2 for node in 1:n)
                else
                    score_courant = nb_conflits(sol_courante, adj)
                end
                push!(sommets_parcourus_plateau, u)
                push!(sommets_parcourus_plateau, v)
                plateau_count += 1
                k_vnd = 1 # On retourne en V_1 pour voir si ce changement a libéré une amélioration 1-color
            else
                # Bloqué à la fois dans V_1 et V_2 : minimum local pour le VND
                break
            end
        end
    end
    return sol_courante, score_courant, a_utilise_v2
end

# Perturbation dans le voisinage k
function perturbation(solution, k, couleurs, adj)
    sol_perturbee = copy(solution)
    n = length(solution)
    
    # On cible les sommets en conflit
    candidats_conflit = get_sommets_en_conflit(sol_perturbee, adj)
    nb_total = min(k, n)
    
    sommets_choisis = Set{Int}()
    
    # On ajoute des sommets en conflit
    for s in candidats_conflit
        if length(sommets_choisis) < nb_total
            push!(sommets_choisis, s)
        end
    end
    
    # Si k est supérieur au nombre de sommets en conflit, on rajoute des voisins de sommets en conflit
    if length(sommets_choisis) < nb_total
        voisins_disponibles = Int[]
        for s in candidats_conflit
            for v in adj[s]
                if !(v in sommets_choisis)
                    push!(voisins_disponibles, v)
                end
            end
        end
        unique!(voisins_disponibles)
        
        # On ajoute ces voisins jusqu'à épuisement ou jusqu'à atteindre nb_total
        for v in voisins_disponibles
            if length(sommets_choisis) < nb_total
                push!(sommets_choisis, v)
            else
                break
            end
        end
    end
    
    # Si k est encore plus grand, on complète avec des sommets aléatoires du graphe
    while length(sommets_choisis) < nb_total
        push!(sommets_choisis, rand(1:n))
    end
    
    for s in sommets_choisis
        autres_couleurs = [c for c in couleurs if c != sol_perturbee[s]]
        if !isempty(autres_couleurs)
            sol_perturbee[s] = rand(autres_couleurs)
        end
    end
    
    return sol_perturbee
end

# Recherche à Voisinage Variable (VNS) avec limite de temps (timer)
function VNS(A, nb_couleurs=6; adj=nothing, max_iter=1000, k_max=10, limite_temps=600, log=true, full_output=false, type_obj="classique")
    debut = time()
    temps_meilleur = 0.0
    eval_counter = Ref(0)
    
    n = size(A, 1)
    couleurs = collect(1:nb_couleurs)
    is_pondere = (type_obj == "pondéré")
    
    # Solution initiale
    solution = dsatur(adj, nb_couleurs)
    meilleure_sol = copy(solution)
    if is_pondere
        meilleurs_conflits = sum(count(v -> meilleure_sol[v] == meilleure_sol[u], adj[u])^2 for u in 1:n)
    else
        meilleurs_conflits = nb_conflits(meilleure_sol, adj)
    end
    conflits_initial = meilleurs_conflits
    conflits_courant = meilleurs_conflits
    
    # Historique des solutions précédentes pour le backtracking
    historique_solutions = Vector{Vector{Int}}()
    
    # Solution de base pour la branche courante
    solution_base_branche = copy(meilleure_sol)
    conflits_base_branche = meilleurs_conflits
    
    # Mémoire pour éviter les cycles sur le plateau courant
    solutions_visitees_plateau = Set{UInt64}()
    push!(solutions_visitees_plateau, hash(solution))
    
    if log
        println("Recherche à Voisinage Variable (VNS) : ")
        println("Sommets : $n | Couleurs cibles : $nb_couleurs | k_max : $k_max | Limite : $(limite_temps)s | Objectif : $type_obj")
        if is_pondere
            println("Score objectif pondéré initial (DSATUR) : $meilleurs_conflits | Conflits réels : $(nb_conflits(meilleure_sol, adj))")
        else
            println("Conflits initiaux (DSATUR) : $meilleurs_conflits")
        end
    end
    
    if meilleurs_conflits == 0
        if log
            println("Solution optimale sans conflit trouvée avec l'heuristique DSATUR")
        end
        duree = time() - debut
        if full_output
            return meilleure_sol, conflits_initial, 0, duree, 0.0, 0.0
        else
            return meilleure_sol, 0
        end
    end
    
    # Descente locale initiale VND (1-color puis 2-color)
    solution, conflits, utilise_v2 = descente_VND(solution, adj, couleurs; eval_counter=eval_counter, type_obj=type_obj)
    desc_init = utilise_v2 ? "V_2" : "V_1"
    if conflits < meilleurs_conflits
        meilleurs_conflits = conflits
        meilleure_sol = copy(solution)
        solution_base_branche = copy(meilleure_sol)
        conflits_base_branche = meilleurs_conflits
        temps_meilleur = time() - debut
        if log
            println("Après descente initiale ($desc_init) -> Conflits : $meilleurs_conflits")
        end
    end
    conflits_courant = conflits
    
    iter = 0
    iter_stagnation = 0
    seuil_stagnation = 25 # Nombre d'itérations sans amélioration avant retour à la solution de base
    nb_stagnations_consecutives = 0
    seuil_backtrack = 5 # Après 5 stagnations de suite sur le même plateau, retour à la solution précédente

    while iter < max_iter && meilleurs_conflits > 0 && (time() - debut < limite_temps)
        iter += 1
        k = 1
        
        while k <= k_max && meilleurs_conflits > 0 && (time() - debut < limite_temps)
            # perturbation dans le voisinage V_k
            sol_prime = perturbation(solution, k, couleurs, adj)
            
            # recherche Locale descente VND (V_1 1-color puis V_2 2-color)
            sol_seconde, conflits_seconde, utilise_v2 = descente_VND(sol_prime, adj, couleurs; eval_counter=eval_counter, type_obj=type_obj)
            desc_type = utilise_v2 ? "V_2" : "V_1"
            
            # changement de voisinage
            if conflits_seconde < meilleurs_conflits
                # Nouveau record, on mémorise l'ancienne solution pour l'historique
                push!(historique_solutions, copy(meilleure_sol))
                if length(historique_solutions) > 20
                    popfirst!(historique_solutions)
                end
                solution = copy(sol_seconde)
                conflits_courant = conflits_seconde
                meilleure_sol = copy(sol_seconde)
                meilleurs_conflits = conflits_seconde
                solution_base_branche = copy(meilleure_sol)
                conflits_base_branche = meilleurs_conflits
                temps_meilleur = time() - debut
                empty!(solutions_visitees_plateau)
                push!(solutions_visitees_plateau, hash(solution))
                iter_stagnation = 0 # Reset de la stagnation
                nb_stagnations_consecutives = 0
                if log
                    println("Itération $iter (shaking k = $k, descente $desc_type) -> Conflits réduits à : $meilleurs_conflits ($(round(time() - debut; digits=1))s)")
                end
                k = 1
            elseif conflits_seconde < conflits_courant
                # Amélioration sur la branche courante
                solution = copy(sol_seconde)
                conflits_courant = conflits_seconde
                empty!(solutions_visitees_plateau)
                push!(solutions_visitees_plateau, hash(solution))
                iter_stagnation = 0
                if log
                    println("Itération $iter (shaking k = $k, descente $desc_type) -> Progrès branche : $conflits_courant conflits")
                end
                k = 1
            elseif conflits_seconde == conflits_courant
                # Mouvement sur le plateau courant avec détection anti-cycle
                h = hash(sol_seconde)
                if !(h in solutions_visitees_plateau)
                    push!(solutions_visitees_plateau, h)
                    solution = copy(sol_seconde)
                end
                k += 1
            else
                # on augmente la taille dz le perturbation pour sortir du minimum local
                k += 1
            end
        end

        # Gestion de la stagnation et du backtracking
        iter_stagnation += 1
        if iter_stagnation >= seuil_stagnation
            nb_stagnations_consecutives += 1
            iter_stagnation = 0
            
            if nb_stagnations_consecutives < seuil_backtrack
                if log
                    println("Itération $iter : Stagnation ($nb_stagnations_consecutives/$seuil_backtrack) -> Retour à la meilleure solution ($meilleurs_conflits conflits)")
                end
                # Retour à la solution de base de la branche en cours (et non à meilleure_sol !)
                solution = copy(solution_base_branche)
                conflits_courant = conflits_base_branche
            else
                # 5 stagnations consécutives sur cette branche : on remonte au niveau précédent
                if !isempty(historique_solutions)
                    solution = pop!(historique_solutions)
                    solution_base_branche = copy(solution)
                    conflits_base_branche = is_pondere ? sum(count(v -> solution[v] == solution[u], adj[u])^2 for u in 1:n) : nb_conflits(solution, adj)
                    conflits_courant = conflits_base_branche
                    empty!(solutions_visitees_plateau)
                    push!(solutions_visitees_plateau, hash(solution))
                    if log
                        println("Itération $iter : Backtracking -> solution précédente ($conflits_courant conflits)")
                    end
                else
                    if log
                        println("Itération $iter : $seuil_backtrack stagnations (historique vide) -> Diversification / Saut ($meilleurs_conflits conflits)")
                    end
                    solution = perturbation(meilleure_sol, min(n ÷ 2, 80), couleurs, adj)
                    solution, conflits_courant, _ = descente_VND(solution, adj, couleurs; eval_counter=eval_counter, type_obj=type_obj)
                    solution_base_branche = copy(solution)
                    conflits_base_branche = conflits_courant
                    empty!(solutions_visitees_plateau)
                    push!(solutions_visitees_plateau, hash(solution))
                end
                nb_stagnations_consecutives = 0
            end
        end
    end
    
    duree_resolution = time() - debut
    vitesse = eval_counter[] / max(duree_resolution, 1e-6)
    if log
        println("Fin VNS")
        if is_pondere
            println("Score objectif pondéré : $meilleurs_conflits | Conflits réels : $(nb_conflits(meilleure_sol, adj)) (en $iter itérations, $(round(duree_resolution; digits=2)) s)")
        else
            println("Conflits : $meilleurs_conflits (en $iter itérations, $(round(duree_resolution; digits=2)) s)")
        end
    end
    if full_output
        return meilleure_sol, conflits_initial, meilleurs_conflits, duree_resolution, temps_meilleur, vitesse
    else
        return meilleure_sol, meilleurs_conflits
    end
end
