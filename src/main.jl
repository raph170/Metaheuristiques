include("heuristiques.jl")
include("data.jl")
include("voisinages.jl")
include("metaheuristiques.jl")
include("solution.jl")
include("VND_VNS.jl")

using Random

dir = "data/graphs"

couleurs = Dict(
    "flat300_26_0.col.txt" => [26,13], "le450_15c.col.txt" => [15,8], "dsjc125.1.col.txt" => [5],
    "dsjc125.9.col.txt" => [44,22] ,"dsjc250.1.col.txt" => [8] , "dsjc250.5.col.txt" => [28], 
    "dsjc250.9.col.txt" => [72,36] , "dsjc1000.5.col.txt" => [86,85,84,42],
    "dsjc1000.9.col.txt" => [224,223,222,111] , "C2000.5.col.txt" => [147,146,73],
    "C4000.5.col.txt" => [261,260,130]
    )
# dsjc250.9.col.txt : 30-50
#  dsjc1000.5.col.txt 50
# dsjc1000.9.col.txt 50 -80
# C2000.5.col.txt 30 
# c 4000 80

# nom_fichier = "dsjc125.1.col.txt"
nom_fichier = "le450_15c.col.txt"
# nom_fichier = "C2000.5.col.txt"
# nom_fichier = "flat300_26_0.col.txt"

avant_graphe = time()
A, adj, n, nombre_aretes = lecture_graphe_avec_voisins(dir * "/" * nom_fichier)
apres_graphe = time()
println("temps creation matrice adjacence : ", apres_graphe - avant_graphe)
k = couleurs[nom_fichier][1]+1


heuristique = aleatoire
limite_temps = 120

# meta_heuristique = "recherche tabou"
# meta_heuristique = "recherche tabou objectif pondéré"
# meta_heuristique = "recherche tabou range len_tabou"
# meta_heuristique = "recuit simulé"
meta_heuristique = "VNS"


#####################
### RECUIT SIMULE ###
#####################
if meta_heuristique == "recuit simulé"
    T = 100
    mu = 0.9
    voisinage = _1_echange

    meilleure_solution, nb_conflits_initial, nb_conflits_final,T, duree_resolution = recuit_simule(adj, k, T, heuristique, voisinage, mu; limite_temps = limite_temps, log=true)
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

    # détermination de la taille de la liste tabou en fonction de la taille de l'instance
    # densite = 2 * nombre_aretes / (n * (n - 1))
    # i = n <= 250 ? 1 : n <= 500 ? 2 : n <= 1000 ? 3 : n <= 2000 ? 4 : 5
    # j = densite <= 0.2 ? 1 : densite <= 0.6 ? 2 : 3
    # len_tabou = [
    #     10 20 30
    #     30 40 50
    #     40 60 80
    #     50 70 90
    #     100 100 100
    # ][i, j]
    # println("len tabou = ", len_tabou)

    len_tabou = nothing # si mis a jour dynamique de len_tabou, sinon : Cf juste au dessus
    meilleure_solution, nb_conflits_initial, nb_conflits_final, duree_resolution, temps_meilleure_solution, vitesse_exploration = recherche_tabou(adj, n, k, heuristique, voisinage, len_tabou ; taille_echantillon=20, taille_voisinage=5, n_iter_max_sans_amelioration=10000, n_perturbation_max_sans_amelioration = 3, limite_temps=limite_temps, log=true)
    println("nb_conflit_initial : ", nb_conflits_initial )                                                                                        
    println("nb_conflit_final : ", nb_conflits_final )
    println("durée de résolution : ", duree_resolution)
    println("temps pour trouver la meilleure solution : ", temps_meilleure_solution)
    println("Nombre de solutions explorées par seconde : ", vitesse_exploration)
    println("Valeur de la fonction objectif pondérée : ", objectif_pondere(meilleure_solution, adj))
end

if meta_heuristique == "recherche tabou objectif pondéré"
    voisinage = _p_echange
    limite_temps = 120
    len_tabou = nothing # si mis a jour dynamique de len_tabou, sinon : Cf juste au dessus
    meilleure_solution, objectif_initial, objectif_final, duree_resolution, temps_meilleure_solution, vitesse_exploration = recherche_tabou(adj, n, k, heuristique, voisinage, len_tabou ; type_obj ="pondéré", taille_echantillon=20, taille_voisinage=5, n_iter_max_sans_amelioration=10000, n_perturbation_max_sans_amelioration = 3, limite_temps=limite_temps, log=true)
    println("Valeur objectif pondérée initiale ", objectif_initial )
    println("Valeur objectif pondérée finale : ", objectif_final )
    println("durée de résolution : ", duree_resolution)
    println("temps pour trouver la meilleure solution : ", temps_meilleure_solution)
    println("Nombre de solutions explorées par seconde : ", vitesse_exploration)
    println("Nombre de conflits final : ", nb_conflits(meilleure_solution, adj))

end

if meta_heuristique == "recherche tabou range len_tabou"
    voisinage = _p_echange
    limite_temps = 180

    len_tabous = [10,30,50,80,150,300]
    resulats = Dict()
    for len_tabou in len_tabous
        println("len tabou = ", len_tabou)
        Random.seed!(1234)
        meilleure_solution, nb_conflits_initial, nb_conflits_final, duree_resolution, temps_meilleure_solution, vitesse_exploration = recherche_tabou(adj, n, k, heuristique, voisinage, len_tabou ; taille_echantillon=20, taille_voisinage=5, n_iter_max_sans_amelioration=5000, n_perturbation_max_sans_amelioration = 3, limite_temps=limite_temps, log=false)

        resulats[len_tabou] = Dict("nb conflits initial" => nb_conflits_initial, "nb conflits final" => nb_conflits_final, "duree resolution" => duree_resolution, "temps meilleure solution" => temps_meilleure_solution, "vitesse exploration" => vitesse_exploration)
        println("len tabou = ", len_tabou)
        println("nb_conflit_initial : ", nb_conflits_initial )
        println("nb_conflit_final : ", nb_conflits_final )
        println("durée de résolution : ", duree_resolution)
        println("temps pour trouver la meilleure solution : ", temps_meilleure_solution)
        println("Nombre de solutions explorées par seconde : ", vitesse_exploration)
    end
    print(resulats)
end


#######################
######### VNS #########
#######################
if meta_heuristique == "VNS"
    # type_obj="classique"
    type_obj="pondere"
    sol, conflits = VNS(A, k; adj=adj, max_iter=2000, k_max=100, limite_temps=limite_temps, type_obj=type_obj)
    println("Conflits finaux VNS : ", conflits)
end
