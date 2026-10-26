function n_conflit(A, solution)
    # fonction évaluant le nombre de conflit d'une solution
    N = 0
    n = size(A)[1]
    for u in 1:(n-1)
        for v in u+1:n 
            if A[u,v] ==1 && (solution[u]==solution[v])
                N += 1
            end
        end
    end
    return N
end