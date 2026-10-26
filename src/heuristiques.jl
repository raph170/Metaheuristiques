using Random

function aleatoire(A,k)
    # affectation d'une couleur aléatoire à chaque sommet du graphe
    n = size(A)[1]
    solution = Dict()
    for u in 1:n
        solution[u] = rand(1:k)
    end
    return solution
end

function greedy(A,k)
    # affectation de la première couleur disponible, les sommets sont parcourus dans 
    # l'ordre numérique
    n = size(A)[1]
    solution = Dict(1=>1)
    for u in 2:n
        couleurs = 1:k
        for v in 1:n
            if size(couleurs)[1] == 1
                break
            end
            if A[u,v]==1
                if v in keys(solution)
                    couleurs = filter(!=(solution[v]), couleurs)
                end
            end
        end
        solution[u] = couleurs[1]
    end
    return sort(solution, rev = false)
end


function greedy_deg(A,k,log=false)
    # affectation de la première couleur disponible, les sommets sont parcourus dans 
    # l'ordre des degrés décroissants
    n = size(A)[1]
    Deg = Dict(i => sum(A[i,:]) for i in 1:n)
    sommets_ordonnes = sort(collect(Deg), by = x -> x[2], rev = true)
    solution = Dict()
    for (u,degrés) in sommets_ordonnes
        if log 
            print("visite sommet ",u," de degrés ",degrés)
        end
        couleurs = 1:k
        for v in 1:n
            if size(couleurs)[1] == 1
                break
            end
            if A[u,v]==1
                if v in keys(solution)
                    couleurs = filter(!=(solution[v]), couleurs)
                end
            end
        end
        solution[u] = couleurs[1]
    end
    return sort(solution, rev = false)
end

