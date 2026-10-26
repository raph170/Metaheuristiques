function liste_fichiers_graphes()
    dir = "C:/Users/rapha/OneDrive/Bureau/ENPC/3A/MPRO/Métaheuristiques/Metaheuristiques/data/graphs"
    fichiers = []
    for nom_fichier in readdir(dir)
        chemin = dir * '/' * nom_fichier
        push!(fichiers, chemin)
    end 
    return fichiers
end

function lecture_graphe(path::String)
    A = nothing
    open(path) do f
        while !eof(f)
            s = readline(f)
            fields = split(s)
            if fields[1] == "p"
                n = parse(Int, fields[3])
                A = zeros(Int, n, n)
            elseif fields[1] == "e"
                u = parse(Int, fields[2])
                v = parse(Int, fields[3])
                A[u, v] = 1
                A[v, u] = 1
            end
        end
    end
    return A
end

function liste_voisins(A)
    #retourne un dictionnaire des voisins de chaque sommet
    n = size(A)[1]
    voisins = Dict(u => [v for v in 1:n if A[u,v] == 1] for u in 1:n)
    return voisins
end

A = lecture_graphe(liste_fichiers_graphes()[1])

liste_voisins(A)