# Liste tous les fichiers .col dans le dossier graphs
function list_graph_files(dir=normpath(joinpath(@__DIR__, "..", "graphs")))
    if !isdir(dir)
        error("dossier $dir n'existe pas.")
    end
    all_files = String[]
    for file_name in readdir(dir)
        if endswith(file_name, ".col")
            push!(all_files, joinpath(dir, file_name))
        end
    end
    return all_files
end

# Retourne la matrice d'adjacence A et les listes de voisins (adj) (pour accéder en temps constant aux voisins d'un sommet ou à son degré)
function read_graph(path::String)
    A = nothing
    adj = Vector{Int}[]
    open(path) do f
        while !eof(f)
            s = strip(readline(f))
            fields = split(s)
            if fields[1] == "p"
                n = parse(Int, fields[3])
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
    return A, adj
end