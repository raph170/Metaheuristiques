using Random
Random.seed!(7)

function aleatoire(A,k)
    # affectation d'une couleur aléatoire à chaque sommet du graphe
    n = size(A)[1]
    solution = Dict()
    for u in 1:n
        solution[u] = rand(1:k)
    end
    return solution
end

function greedy(A, adj, k)
    # affectation de la première couleur disponible, les sommets sont parcourus dans 
    # l'ordre numérique
    n = size(A)[1]
    solution = Dict(1=>1)
    for u in 2:n
        couleurs = 1:k
        for v in adj[u]
            if size(couleurs)[1] == 1
                break
            end
            if v in keys(solution)
                couleurs = filter(!=(solution[v]), couleurs)
            end
        end
        solution[u] = couleurs[1]
    end
    return sort(solution, rev = false)
end


function greedy_deg(A, adj, k,log=false)
    # affectation de la première couleur disponible, les sommets sont parcourus dans 
    # l'ordre des degrés décroissants
    n = size(A)[1]
    Deg = Dict(u => length(adj[u]) for u in 1:n)
    sommets_ordonnes = sort(collect(Deg), by = x -> x[2], rev = true)
    solution = Dict()
    for (u,degrés) in sommets_ordonnes
        if log 
            print("visite sommet ",u," de degrés ",degrés)
        end
        couleurs = 1:k
        for v in adj[u]
            if size(couleurs)[1] == 1
                break
            end
            if v in keys(solution)
                couleurs = filter(!=(solution[v]), couleurs)
            end
        end
        solution[u] = couleurs[1]
    end
    return sort(solution, rev = false)
end

# Heuristique DSATUR
# À chaque étape, on sélectionne dynamiquement le sommet qui a le plus grand nombre de couleurs différentes parmi ses voisins
function dsatur(adj, k)
    n = length(adj)
    couleurs = 1:k
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