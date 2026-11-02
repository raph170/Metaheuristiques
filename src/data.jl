function liste_fichiers_graphes(dir)
    fichiers = []
    for nom_fichier in readdir(dir)
        chemin =  nom_fichier
        push!(fichiers, chemin)
    end 
    return fichiers
end

function lecture_graphe_avec_voisins(path::String)
    A = nothing
    n = nothing
    e = nothing
    adj = Vector{Int}[]

    open(path) do f
        while !eof(f)
            s = strip(readline(f))
            fields = split(s)

            if isempty(fields)
                continue
            elseif fields[1] == "p"
                n = parse(Int, fields[3])
                e = parse(Int, fields[4])
                A = zeros(Int, n, n)
                adj = [Int[] for _ in 1:n]

            elseif fields[1] == "e"
                u = parse(Int, fields[2])
                v = parse(Int, fields[3])

                A[u, v] = 1
                A[v, u] = 1
                push!(adj[u], v)
                push!(adj[v], u)
            end
        end
    end

    return A, adj, n, e
end


