include("heuristiques.jl")
include("data.jl")
include("metaheuristiques.jl")

A = lecture_graphe(liste_fichiers_graphes()[1])
k = 10


solution_aleatoire = aleatoire(A,k)
solution_greedy = greedy(A,k)
solution_greedy_deg = greedy_deg(A,k)

N_conflit_random = n_conflit(A,solution_aleatoire)
N_conflit_greedy = n_conflit(A,solution_greedy)
N_conflit_greedy_deg = n_conflit(A,solution_greedy_deg)



# println("nombre de conflit random : ",N_conflit_random)
# println("nombre de conflit greedy : ",N_conflit_greedy)
# println("nombre de conflit greedy degrés : ",N_conflit_greedy_deg)

T = 100
mu = 0.9
heuristique = aleatoire
voisinage = voisinage_2_swap
n_iter_max = 1000

meilleure_solution, nb_conflits_initial, nb_conflits_final = recuit_simule(A, k, T, heuristique, voisinage, mu, n_iter_max)
println("nb_conflit_initial : ", nb_conflits_initial )
println("nb_conflit_final : ", nb_conflits_final )