using Combinatorics
using StatsBase

# couleurs = [1, 2, 3]
# solution_courante = [1, 3, 2]

# on échange la couleur de 2 sommets (avec ce voisinage, le nombre de somments de la couleur i ne varie pas, ce qui peut être problématique)
function voisinage_2_echange(solution)
    n = length(solution)
    voisinage = []
    for i in 1:n
        for j in (i+1):n
            new_sol = copy(solution)
            new_sol[i], new_sol[j] = new_sol[j], new_sol[i]
            push!(voisinage, (new_sol,Dict(i=>solution[j],j=>solution[i])))
        end
    end
    return voisinage
end

function _2_echange(solution)
    #retourne un seul voisin
    n = length(solution)
    i, j = rand(1:n, 2)
    while i == j
        j = rand(1:n)
    end
    new_sol = copy(solution)
    new_sol[i], new_sol[j] = new_sol[j], new_sol[i]
    return (new_sol,Dict(i=>solution[i],j=>solution[j]))
end
     

# on change la couleur de 1 sommets
function voisinage_1_echange(solution, k)
    n = length(solution)
    colors = 1:k
    voisinage = []
    for i in 1:n
        for color in colors
            if solution[i] != color
                new_sol = copy(solution)
                ancienne_couleur = solution[i]
                new_sol[i] = color
                push!(voisinage, (new_sol,Dict(i=>ancienne_couleur)))
            end
        end
    end
    return voisinage
end

function _1_echange(solution, k)
    #retourne un seul voisin
    n = length(solution)
    i = rand(1:n)
    c = rand(1:k)
    while c == solution[i] && k > 1
        c = rand(1:k)
    end
    new_sol = copy(solution)
    new_sol[i] = c
    return (new_sol,Dict(i=>solution[i]))
end

# on change la couleur de k sommets
function voisinage_k_color(solution, k)
    colors = 1:k
    if k <= 0
        return []
    end
    if k == 1
        return voisinage_1_color(solution, colors)
    end
    if k > length(solution)
        return []
    end

    n = length(solution)
    voisinage = []

    # pour toutes les combinaisons de k sommets distincts
    for sommets in combinations(1:n, k)
        curr_sols = [copy(solution)]
        # Pour chacun des k sommets, on déploie les nouvelles couleurs
        for sommet in sommets
            next_sols = []
            for sol in curr_sols
                for color in colors
                    if color != solution[sommet]
                        new_sol = copy(sol)
                        new_sol[sommet] = color
                        push!(next_sols, new_sol)
                    end
                end
            end
            curr_sols = next_sols
        end
        append!(voisinage, curr_sols)
    end
    return voisinage
end

function _p_echange(solution, k, p)
    #retourne un seul voisin
    n = length(solution)
    sommets = sample(1:n, p, replace=false) # p sommets distincts 2 à 2
    new_sol = deepcopy(solution)
    avant_changements = Dict()
    for u in sommets
        c = rand(1:k)
        while c == solution[u]
            c = rand(1:k)
        end
        new_sol[u] = c
        avant_changements[u] = solution[u]
    end
    return (new_sol,avant_changements)
end

# println("Voisinage 2-swap  : ", voisinage_2_echange(solution_courante), " voisins")
# println("Voisinage 1-color : ", voisinage_1_echange(solution_courante, couleurs), " voisins")
# println("Voisinage 2-color : ", voisinage_k_color(3, solution_courante, couleurs), " voisins")