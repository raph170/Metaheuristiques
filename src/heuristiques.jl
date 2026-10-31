# Heuristiques pour la coloration de graphe

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

# Heuristique DSATUR
# À chaque étape, on sélectionne dynamiquement le sommet qui a le plus grand nombre de couleurs différentes parmi ses voisins
function dsatur(adj, couleurs)
    n = length(adj)
    solution = zeros(Int, n)
    degres = [length(adj[i]) for i in 1:n]
    
    # Pour chaque sommet, l'ensemble des couleurs différentes parmis ses voisins
    couleurs_voisins = [Set{Int}() for _ in 1:n]
    
    for step in 1:n
        # Trouver le sommet non colorié avec le plus grand DSAT
        # En cas d'égalité, on choisi celui avec le plus grand degré
        meilleur_sommet = -1
        max_dsat = -1
        max_deg = -1
        
        for i in 1:n
            if solution[i] == 0
                dsat_i = length(couleurs_voisins[i])
                deg_i = degres[i]
                
                if dsat_i > max_dsat || (dsat_i == max_dsat && deg_i > max_deg)
                    max_dsat = dsat_i
                    max_deg = deg_i
                    meilleur_sommet = i
                end
            end
        end
        
        s = meilleur_sommet
        
        # on attribue la meilleure couleur pour s
        disponibles = [c for c in couleurs if !(c in couleurs_voisins[s])]
        
        if !isempty(disponibles)
            solution[s] = disponibles[1] # Première couleur sans conflit
        else
            # Si aucune couleur libre, on choisit celle qui crée le moins de conflits avec ses voisins
            meilleure_c = couleurs[1]
            min_conflits = typemax(Int)
            for c in couleurs
                nb_conf = count(v -> solution[v] == c, adj[s])
                if nb_conf < min_conflits
                    min_conflits = nb_conf
                    meilleure_c = c
                end
            end
            solution[s] = meilleure_c
        end
        
        # Maj du DSAT des voisins de s non coloriés
        c_attribuee = solution[s]
        for v in adj[s]
            if solution[v] == 0
                push!(couleurs_voisins[v], c_attribuee)
            end
        end
    end
    
    return solution
end
