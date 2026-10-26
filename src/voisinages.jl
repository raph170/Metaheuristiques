using Combinatorics

couleurs = [1, 2, 3]
solution_courante = [1, 3, 2]

# on échange la couleur de 2 sommets (avec ce voisinage, le nombre de somments de la couleur i ne varie pas, ce qui peut être problématique)
function voisinage_2_swap(solution)
    l = length(solution)
    voisinage = []
    for i in 1:l
        for j in (i+1):l
            new_sol = copy(solution)
            new_sol[i], new_sol[j] = new_sol[j], new_sol[i]
            push!(voisinage, new_sol)
        end
    end
    return voisinage
end

# on change la couleur de 1 sommets
function voisinage_1_color(solution, colors)
    l = length(solution)
    voisinage = []
    for i in 1:l
        for color in colors
            if solution[i] != color
                new_sol = copy(solution)
                new_sol[i] = color
                push!(voisinage, new_sol)
            end
        end
    end
    return voisinage
end

# on change la couleur de k sommets
function voisinage_k_color(k, solution, colors)
    if k <= 0
        return []
    end
    if k == 1
        return voisinage_1_color(solution, colors)
    end
    if k > length(solution)
        return []
    end

    l = length(solution)
    voisinage = []

    # pour toutes les combinaisons de k sommets distincts
    for sommets in combinations(1:l, k)
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

# println("Voisinage 2-swap  : ", voisinage_2_swap(solution_courante), " voisins")
# println("Voisinage 1-color : ", voisinage_1_color(solution_courante, couleurs), " voisins")
# println("Voisinage 2-color : ", voisinage_k_color(3, solution_courante, couleurs), " voisins")