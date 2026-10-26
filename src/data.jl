function list_graph_files()
    dir = "C:/Users/rapha/OneDrive/Bureau/ENPC/3A/MPRO/Métaheuristiques/Metaheuristiques/data/graphs"
    all_files = []
    for file_name in readdir(dir)
        file_path = dir * '/' * file_name
        push!(all_files, file_path)
    end 
    return all_files
end

function read_graph(path::String)
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