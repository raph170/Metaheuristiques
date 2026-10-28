include("heuristiques.jl")
include("data.jl")
include("metaheuristiques.jl")
include("solution.jl")

using Random
# using time

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
mu = 0.85
heuristique = aleatoire
voisinage = voisinage_2_echange
n_iter_max = 1000

# meilleure_solution, nb_conflits_initial, nb_conflits_final = recuit_simule(A, k, T, heuristique, voisinage, mu, n_iter_max)

len_tabou = 10
debut_resolution = time()
meilleure_solution, nb_conflits_initial, nb_conflits_final = recherche_tabou(A, k, heuristique, voisinage, len_tabou, n_iter_max, true)
fin_resolution = time()

println("nb_conflit_initial : ", nb_conflits_initial )
println("nb_conflit_final : ", nb_conflits_final )
println("durée de résolution : ", fin_resolution - debut_resolution)

# len_tabous = [5*i for i in 0:25]
# resulats = Dict()
# for len_tabou in len_tabous
#     Random.seed!(1234)
#     debut_resolution = time()
#     meilleure_solution, nb_conflits_initial, nb_conflits_final = recherche_tabou(A, k, heuristique, voisinage, len_tabou, n_iter_max)
#     fin_resolution = time()
#     resulats[len_tabou] = Dict("nb conflits final" => nb_conflits_final, "temps resolution" => fin_resolution - debut_resolution)
#     println("len tabou = ", len_tabou)
#     println("nb_conflit_initial : ", nb_conflits_initial )
#     println("nb_conflit_final : ", nb_conflits_final )
#     println("durée de résolution : ", fin_resolution - debut_resolution)
# end
# print(resulats)
