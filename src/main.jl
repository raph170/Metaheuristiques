include("data.jl")
include("voisinages.jl")
include("heuristiques.jl")

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
    
    for u in sommets_conf
        c_u_orig = solution[u]
        
        for v in adj[u]
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
function descente_VND(solution, adj, couleurs; max_iter=500, max_plateau=25)
    sol_courante = copy(solution)
    conflits_courant = nb_conflits(sol_courante, adj)
    max_c = maximum(couleurs)
    
    iter = 0
    plateau_count = 0
    sommets_parcourus_plateau = Set{Int}() # les sommets modifiés sur ce plateau (pour éviter les cycles)
    freq_couleurs = zeros(Int, max_c)
    
    k_vnd = 1 # Ordre du voisinage de descente : 1 = 1-color, 2 = 2-color
    a_utilise_v2 = false
    
    while conflits_courant > 0 && iter < max_iter
        iter += 1
        
        # On teste les sommets qui posent un problème
        sommets_conf = get_sommets_en_conflit(sol_courante, adj)
        if isempty(sommets_conf)
            break
        end
        
        # Stratégie Best Improvement : recherche du meilleur mouvement (s*, c*) sur tout le voisinage
        if k_vnd == 1
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
                for v in adj[s]
                    col_v = sol_courante[v]
                    if col_v > 0 && col_v <= max_c
                        freq_couleurs[col_v] += 1
                    end
                end
                conflits_actuels_de_s = freq_couleurs[c_orig]
                
                for c in couleurs
                    if c != c_orig
                        # (conflits créés avec c) - (conflits supprimés de c_orig)
                        delta = freq_couleurs[c] - conflits_actuels_de_s
                        
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
                sol_courante[meilleur_s] = meilleur_c
                conflits_courant += meilleur_delta
                plateau_count = 0 # Reset du plateau après une vraie amélioration
                empty!(sommets_parcourus_plateau)
                k_vnd = 1 # Reste dans V_1
            elseif mvt_neutre_trouve && plateau_count < max_plateau
                # Mouvement neutre pour naviguer sur le plateau
                sol_courante[sommet_neutre] = couleur_neutre
                push!(sommets_parcourus_plateau, sommet_neutre) # On verrouille ce sommet pour ce plateau
                plateau_count += 1
            else
                # Bloqué dans V_1 -> on tente le voisinage V_2 (2-color)
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
                conflits_courant = nb_conflits(sol_courante, adj)
                plateau_count = 0
                empty!(sommets_parcourus_plateau)
                k_vnd = 1 # retour au voisinage V_1
            elseif delta_2 == 0 && u != -1 && plateau_count < max_plateau
                # Mouvement neutre en 2-color pour naviguer sur le plateau (anti-cycle)
                sol_courante[u] = cu
                sol_courante[v] = cv
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
    return sol_courante, conflits_courant, a_utilise_v2
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
    
    # Si k est supérieur au nombre de conflits, on rajoute des voisins de sommets en conflit
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
    
    # si k est encore plus grand, on complète avec n'importe quel sommet du graphe
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

# Recherche à Voisinage Variable (VNS)
function VNS(A, nb_couleurs=6; adj=nothing, max_iter=1000, k_max=10)
    n = size(A, 1)
    couleurs = collect(1:nb_couleurs)
    
    # Solution initiale
    solution = dsatur(adj, couleurs)
    meilleure_sol = copy(solution)
    meilleurs_conflits = nb_conflits(meilleure_sol, adj)
    conflits_courant = meilleurs_conflits
    
    # Historique des solutions précédentes pour le backtracking
    historique_solutions = Vector{Vector{Int}}()
    
    # Solution de base pour la branche courante
    solution_base_branche = copy(meilleure_sol)
    conflits_base_branche = meilleurs_conflits
    
    # Mémoire pour éviter les cycles sur le plateau courant
    solutions_visitees_plateau = Set{UInt64}()
    push!(solutions_visitees_plateau, hash(solution))
    
    println("Recherche à Voisinage Variable (VNS) : ")
    println("Sommets : $n | Couleurs cibles : $nb_couleurs | k_max : $k_max")
    println("Conflits : $meilleurs_conflits")
    
    if meilleurs_conflits == 0
        println("Solution optimale sans conflit trouvée avec l'heuristique gloutonne")
        return meilleure_sol, 0
    end
    
    # Descente locale initiale VND (1-color puis 2-color)
    solution, conflits, utilise_v2 = descente_VND(solution, adj, couleurs)
    desc_init = utilise_v2 ? "V_2" : "V_1"
    if conflits < meilleurs_conflits
        meilleurs_conflits = conflits
        meilleure_sol = copy(solution)
        solution_base_branche = copy(meilleure_sol)
        conflits_base_branche = meilleurs_conflits
        println("Après descente initiale ($desc_init) -> Conflits : $meilleurs_conflits")
    end
    conflits_courant = conflits
    
    iter = 0
    iter_stagnation = 0
    seuil_stagnation = 25 # Nombre d'itérations sans amélioration avant retour à la solution de base
    nb_stagnations_consecutives = 0
    seuil_backtrack = 5 # Après 5 stagnations de suite sur le même plateau, retour à la solution précédente

    while iter < max_iter && meilleurs_conflits > 0
        iter += 1
        k = 1
        
        while k <= k_max && meilleurs_conflits > 0
            # perturbation dans le voisinage V_k
            sol_prime = perturbation(solution, k, couleurs, adj)
            
            # recherche Locale descente VND (V_1 1-color puis V_2 2-color)
            sol_seconde, conflits_seconde, utilise_v2 = descente_VND(sol_prime, adj, couleurs)
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
                empty!(solutions_visitees_plateau)
                push!(solutions_visitees_plateau, hash(solution))
                iter_stagnation = 0 # Reset de la stagnation
                nb_stagnations_consecutives = 0
                println("Itération $iter (shaking k = $k, descente $desc_type) -> Conflits réduits à : $meilleurs_conflits")
                k = 1
            elseif conflits_seconde < conflits_courant
                # Amélioration sur la branche courante
                solution = copy(sol_seconde)
                conflits_courant = conflits_seconde
                empty!(solutions_visitees_plateau)
                push!(solutions_visitees_plateau, hash(solution))
                iter_stagnation = 0
                println("Itération $iter (shaking k = $k, descente $desc_type) -> Progrès branche : $conflits_courant conflits")
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
                println("Itération $iter : Stagnation ($nb_stagnations_consecutives/$seuil_backtrack) -> Retour à la meilleure solution ($meilleurs_conflits conflits)")
                # Retour à la solution de base de la branche en cours (et non à meilleure_sol !)
                solution = copy(solution_base_branche)
                conflits_courant = conflits_base_branche
            else
                # 5 stagnations consécutives sur cette branche : on remonte au niveau précédent
                if !isempty(historique_solutions)
                    solution = pop!(historique_solutions)
                    solution_base_branche = copy(solution)
                    conflits_base_branche = nb_conflits(solution, adj)
                    conflits_courant = conflits_base_branche
                    empty!(solutions_visitees_plateau)
                    push!(solutions_visitees_plateau, hash(solution))
                    println("Itération $iter : Backtracking -> solution précédente ($conflits_courant conflits)")
                else
                    println("Itération $iter : $seuil_backtrack stagnations (historique vide) -> Diversification / Saut ($meilleurs_conflits conflits)")
                    solution = perturbation(meilleure_sol, min(n ÷ 2, 80), couleurs, adj)
                    solution, conflits_courant, _ = descente_VND(solution, adj, couleurs)
                    solution_base_branche = copy(solution)
                    conflits_base_branche = conflits_courant
                    empty!(solutions_visitees_plateau)
                    push!(solutions_visitees_plateau, hash(solution))
                end
                nb_stagnations_consecutives = 0
            end
        end
    end
    
    println("Fin VNS")
    println("Conflits : $meilleurs_conflits (en $iter itérations)")
    return meilleure_sol, meilleurs_conflits
end

# Format : (nom_fichier, nb_couleurs_optimales)
graphes = [
    ("dsjc125.1.col", 5),       # n=125, couleur = 5, ok
    ("dsjc125.9.col", 44),      # n=125, couleur = 44, ok
    ("dsjc250.1.col", 8),       # n=250, couleur = 8, non
    ("dsjc250.5.col", 28),      # n=250, couleur = 28, non
    ("dsjc250.9.col", 72),      # n=250, couleur = 72, non
    ("flat300_26_0.col", 26),   # n=300, couleur = 26, 
    ("le450_15c.col", 15),      # n=450, couleur = 15, 
    ("dsjc1000.5.col", 83),     # n=1000, couleur = 83, 
    ("dsjc1000.9.col", 223),    # n=1000, couleur = 223, 
    ("C2000.5.col", 145),       # n=2000, couleur = 145, 
    ("C4000.5.col", 260)        # n=4000, couleur = 260, 
]

for i in 1:length(graphes)
    nom_graphe, nb_c = graphes[i]

    graphe_path = normpath(joinpath(@__DIR__, "..", "graphs", nom_graphe))
    println("Test sur $graphe_path ($nb_c couleurs cibles)")
    A, adj = read_graph(graphe_path)
    sol, conflits = VNS(A, nb_c; adj=adj, max_iter=2000, k_max=50)
end
