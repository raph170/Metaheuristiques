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

# Choix du graphe (a selectionner)
nom_fichier = "dsjc125.1.col.txt"

avant_graphe = time()
A, adj, n, nombre_aretes = lecture_graphe_avec_voisins(dir * "/" * nom_fichier)
apres_graphe = time()
println("temps creation matrice adjacence : ", apres_graphe - avant_graphe)

# CHoix du nombre de couleurs (a selectionner) :
k = couleurs[nom_fichier][1]+1

# Choix de l'heuristique pour la solution initiale (a selectionner)
heuristique = aleatoire

# Limite de temps (a selectionner)
limite_temps = 120

# Choix de la méthode de résolution (a selectionner) :

meta_heuristique = "recherche tabou"
# meta_heuristique = "recherche tabou objectif pondéré"
# meta_heuristique = "recuit simulé"
# meta_heuristique = "VNS"
# meta_heuristique = "VNS objectif pondéré"


#####################
### RECUIT SIMULE ###
#####################
if meta_heuristique == "recuit simulé"
    T = 200 
    mu = 0.99
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
    println("Valeur de la fonction objectif pondérée : ", objectif_pondere(meilleure_solution, adj, k))
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



#######################
######### VNS #########
#######################
if meta_heuristique == "VNS"
    type_obj="classique"
    meilleur_solution, nb_conflits_final = VNS(A, k; adj=adj, max_iter=2000, k_max=100, limite_temps=limite_temps, type_obj=type_obj)
    println("Conflits finaux VNS : ", conflits)
end

if meta_heuristique == "VNS objectif pondéré"
    type_obj="pondere"
    meilleur_solution, nb_conflits_final = VNS(A, k; adj=adj, max_iter=2000, k_max=100, limite_temps=limite_temps, type_obj=type_obj)
    println("Conflits finaux VNS pondérée : ", conflits)
end


couleurs = Dict(
     "dsjc125.1.col.txt" => [5],
    "dsjc250.9.col.txt" => [72] ,
    "dsjc1000.9.col.txt" => [224] , "C2000.5.col.txt" => [147],
    "C4000.5.col.txt" => [261]
    )


limite_temps = 300
for (graphe, liste_k) in couleurs
    for k in liste_k
        nom_fichier = graphe
        avant_graphe = time()
        A, adj, n, nombre_aretes = lecture_graphe_avec_voisins(dir * "/" * nom_fichier)
        apres_graphe = time()
        for type_obj in ["classique", "pondéré"]
            Random.seed!(1234)
            meilleure_solution, nb_conflits_initial, nb_conflits_final, duree_resolution, temps_meilleure_solution, vitesse_exploration = VNS(A, k; adj=adj, max_iter=2000, k_max=100, limite_temps=limite_temps, log = false, full_output=true, type_obj=type_obj)
            if type_obj == "classique"
                println("graphe : ",graphe, " | k = ", k, " | type d'objectif : ",type_obj)   
                println("nb_conflit_initial : ", nb_conflits_initial )                                                                                    
                println("nb_conflit_final : ", nb_conflits_final )
                println("durée de résolution : ", duree_resolution)
                println("temps pour trouver la meilleure solution : ", temps_meilleure_solution)
                println("Nombre de solutions explorées par seconde : ", vitesse_exploration)
                println("Valeur de la fonction objectif pondérée : ", objectif_pondere(meilleure_solution, adj,k))
            else
                println("graphe : ",graphe, " | k = ", k, " | type d'objectif : ",type_obj)
                println("Valeur objectif pondérée initiale ", nb_conflits_initial )
                println("Valeur objectif pondérée finale : ", nb_conflits_final )
                println("durée de résolution : ", duree_resolution)
                println("temps pour trouver la meilleure solution : ", temps_meilleure_solution)
                println("Nombre de solutions explorées par seconde : ", vitesse_exploration)
                println("Nombre de conflits final : ", nb_conflits(meilleure_solution, adj))
            end
        end
    end
end
