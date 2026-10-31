include("heuristiques.jl")
include("data.jl")
include("metaheuristiques.jl")
include("solution.jl")
using Random

dir = "C:/Users/rapha/OneDrive/Bureau/ENPC/3A/MPRO/Métaheuristiques/Metaheuristiques/data/graphs/"

couleurs = Dict(
    "flat300_26_0.col.txt" => [26,13], "le450_15c.col.txt" => [15,8], "dsjc125.1.col.txt" => [5],
    "dsjc125.9.col.txt" => [44,22] ,"dsjc250.1.col.txt" => [8] , "dsjc250.5.col.txt" => [28], 
    "dsjc250.9.col.txt" => [72,36] , "dsjc1000.5.col.txt" => [86,85,84,42],
    "dsjc1000.9.col.txt" => [224,223,222,111] , "C2000.5.col.txt" => [147,146,73],
    "C4000.5.col.txt" => [261,260,130]
    )

nom_fichier = "le450_15c.col.txt"

avant_graphe = time()
A = lecture_graphe(dir * "/" * nom_fichier)
apres_graphe = time()
println("temps creation matrice adjacence : ", apres_graphe - avant_graphe)
k = couleurs[nom_fichier][1]


# solution_aleatoire = aleatoire(A,k)
# solution_greedy = greedy(A,k)
# solution_greedy_deg = greedy_deg(A,k)

# N_conflit_random = n_conflit(A,solution_aleatoire)
# N_conflit_greedy = n_conflit(A,solution_greedy)
# N_conflit_greedy_deg = n_conflit(A,solution_greedy_deg)

# println("nombre de conflit random : ",N_conflit_random)
# println("nombre de conflit greedy : ",N_conflit_greedy)
# println("nombre de conflit greedy degrés : ",N_conflit_greedy_deg)


heuristique = aleatoire
limite_temps = 120

# meta_heuristique = "recherche tabou"
meta_heuristique = "recherche tabou range len_tabou"
# meta_heuristique = "recuit simulé"


#####################
### RECUIT SIMULE ###
#####################
if meta_heuristique == "recuit simulé"
    T = 200
    mu = 0.99
    voisinage = _1_echange

    meilleure_solution, nb_conflits_initial, nb_conflits_final,T, duree_resolution = recuit_simule(A, k, T, heuristique, voisinage, mu, n_iter_max, true)
    println("nb_conflit_initial : ", nb_conflits_initial )
    println("nb_conflit_final : ", nb_conflits_final )
    println("durée de résolution : ", duree_resolution)
    println("T = ",T)
end


#######################
### RECHERCHE TABOU ###
#######################

if meta_heuristique == "recherche tabou"
    voisinage = _p_echange

    len_tabou = 100
    
    meilleure_solution, nb_conflits_initial, nb_conflits_final, duree_resolution, temps_meilleure_solution, vitesse_exploration = recherche_tabou(A, k, heuristique, voisinage, len_tabou, n_iter_max, taille_echantillon = 10, p = 10, limite_temps = 180, log = true)
    println("nb_conflit_initial : ", nb_conflits_initial )
    println("nb_conflit_final : ", nb_conflits_final )
    println("durée de résolution : ", duree_resolution)
    println("temps pour trouver la meilleure solution : ", temps_meilleure_solution)
    println("Nombre de solutions explorées par seconde : ", vitesse_exploration)
end



if meta_heuristique == "recherche tabou range len_tabou"
    voisinage = _p_echange
    limite_temps = 120

    len_tabous = [10,30,50,80,150,300]
    resulats = Dict()
    for len_tabou in len_tabous
        Random.seed!(1234)
        meilleure_solution, nb_conflits_initial, nb_conflits_final, duree_resolution, temps_meilleure_solution, vitesse_exploration = recherche_tabou(A, k, heuristique, voisinage, len_tabou ; taille_echantillon=10, taille_voisinage=5, n_iter_max_sans_amelioration=2000, limite_temps=limite_temps, log=false)

        resulats[len_tabou] = Dict("nb conflits initial" => nb_conflits_initial, "nb conflits final" => nb_conflits_final, "temps resolution" => temps_resolution, "temps meilleure solution" => temps_meilleure_solution, "vitesse exploration" => vitesse_exploration)
        println("len tabou = ", len_tabou)
        println("nb_conflit_initial : ", nb_conflits_initial )
        println("nb_conflit_final : ", nb_conflits_final )
        println("durée de résolution : ", duree_resolution)
        println("temps pour trouver la meilleure solution : ", temps_meilleure_solution)
        println("Nombre de solutions explorées par seconde : ", vitesse_exploration)
    end
    print(resulats)
end


