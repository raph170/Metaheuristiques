function liste_fichiers_graphes(dir)
    fichiers = []
    for nom_fichier in readdir(dir)
        chemin =  nom_fichier
        push!(fichiers, chemin)
    end 
    return fichiers
end

function lecture_graphe(path::String)
    A = nothing
    n = nothing
    e = nothing
    open(path) do f
        while !eof(f)
            s = readline(f)
            fields = split(s)
            if fields[1] == "p"
                n = parse(Int, fields[3])
                e = parse(Int, fields[4])
                A = zeros(Int, n, n)
            elseif fields[1] == "e"
                u = parse(Int, fields[2])
                v = parse(Int, fields[3])
                A[u, v] = 1
                A[v, u] = 1
            end
        end
    end
    return A, n, e
end

function liste_voisins(A,n)
    #retourne un dictionnaire des voisins de chaque sommet
    voisins = Dict(u => [v for v in 1:n if A[u,v] == 1] for u in 1:n)
    return voisins
end
