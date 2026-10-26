include("data.jl")
include("voisinages.jl")

# nombre d'arêtes en conflit (même couleur aux 2 extrémités)
function nb_conflits(solution, adj)
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

# Heuristique gloutonne (tri des sommets par degré décroissant)
function solution_gloutonne(adj, couleurs)
    n = length(adj)
    degres = [length(adj[i]) for i in 1:n] # Degré en O(1) grâce à adj
    ordre = sortperm(degres, rev=true)     # tri des sommets et renvoie les indices dans l'ordre décroissant
    
    solution = zeros(Int, n)
    for s in ordre
        # Couleurs déjà prises par les voisins de s
        couleurs_voisins = Set{Int}()
        for v in adj[s]
            if solution[v] != 0
                push!(couleurs_voisins, solution[v])
            end
        end
        
        # Première couleur disponible sans conflit immédiat
        disponibles = [c for c in couleurs if !(c in couleurs_voisins)]
        if !isempty(disponibles)
            solution[s] = disponibles[1]
        else
            solution[s] = rand(couleurs)
        end
    end
    return solution
end

# Recherche Locale : descente (First Improvement) dans le 1-voisinage
function descente_locale(solution, adj, couleurs; max_iter=300)
    sol_courante = copy(solution)
    conflits_courant = nb_conflits(sol_courante, adj)
    
    ameliore = true
    iter = 0
    while ameliore && conflits_courant > 0 && iter < max_iter
        ameliore = false
        iter += 1
        
        # On teste les sommets qui posent un problème
        sommets_conf = get_sommets_en_conflit(sol_courante, adj)
        
        for s in sommets_conf
            c_orig = sol_courante[s]
            for c in couleurs
                if c != c_orig
                    sol_courante[s] = c
                    nouveaux_conflits = nb_conflits(sol_courante, adj)
                    
                    if nouveaux_conflits < conflits_courant
                        conflits_courant = nouveaux_conflits
                        ameliore = true
                        break # on s'arrête dès qu'on trouve une meilleure solution
                    else
                        sol_courante[s] = c_orig # Annuler la modification
                    end
                end
            end
            if ameliore
                break
            end
        end
    end
    return sol_courante, conflits_courant
end

# Perturbation dans le voisinage k
function perturbation(solution, k, couleurs, adj)
    sol_perturbee = copy(solution)
    n = length(solution)
    
    # On cible les sommets en conflit
    candidats = get_sommets_en_conflit(sol_perturbee, adj)
    if isempty(candidats)
        candidats = collect(1:n) # tous les sommets sont candidats
    end
    
    nb_a_changer = min(k, length(candidats))
    
    # Tirage de nb_a_changer sommets distincts parmi les candidats
    sommets_choisis = Set{Int}()
    while length(sommets_choisis) < nb_a_changer
        push!(sommets_choisis, rand(candidats))
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
function VNS(A, nb_couleurs=6; adj, max_iter=1000, k_max=10)
    n = size(A, 1)
    couleurs = collect(1:nb_couleurs)
    
    # Solution initiale
    solution = solution_gloutonne(adj, couleurs)
    meilleure_sol = copy(solution)
    meilleurs_conflits = nb_conflits(meilleure_sol, adj)
    
    println("Recherche à Voisinage Variable (VNS) : ")
    println("Sommets : $n | Couleurs cibles : $nb_couleurs | k_max : $k_max")
    println("Conflits : $meilleurs_conflits")
    
    if meilleurs_conflits == 0
        println("Solution optimale sans conflit trouvée avec l'heuristique gloutonne")
        return meilleure_sol, 0
    end
    
    # Descente locale initiale
    solution, conflits = descente_locale(solution, adj, couleurs)
    if conflits < meilleurs_conflits
        meilleurs_conflits = conflits
        meilleure_sol = copy(solution)
        println("Après descente initiale -> Conflits : $meilleurs_conflits")
    end
    
    iter = 0
    while iter < max_iter && meilleurs_conflits > 0
        iter += 1
        k = 1
        
        while k <= k_max && meilleurs_conflits > 0
            # perturbation dans le voisinage V_k
            sol_prime = perturbation(solution, k, couleurs, adj)
            
            # recherche Locale descente dans V_1
            sol_seconde, conflits_seconde = descente_locale(sol_prime, adj, couleurs)
            
            # changement de voisinage
            if conflits_seconde < meilleurs_conflits
                # on conserve la solution et on revient au voisinage le plus petit (k = 1)
                solution = copy(sol_seconde)
                meilleure_sol = copy(sol_seconde)
                meilleurs_conflits = conflits_seconde
                println("Itération $iter (ordre voisinage = $k) -> Conflits réduits à : $meilleurs_conflits")
                k = 1
            else
                # on augmente la taille dz le perturbation pour sortir du minimum local
                k += 1
            end
        end
    end
    
    println("Fin VNS")
    println("Conflits : $meilleurs_conflits (en $iter itérations)")
    return meilleure_sol, meilleurs_conflits
end

# Exemple :
graphe_path = normpath(joinpath(@__DIR__, "..", "graphs", "dsjc125.1.col"))
println("Test sur $graphe_path")
A, adj = read_graph(graphe_path)
sol, conflits = VNS(A, 5; adj=adj, max_iter=2000, k_max=50)
