# test.jl : test automatisé de toutes les métaheuristiques sur les instances
# Usage :
#   julia test.jl          -> Exécute avec le temps par défaut (600s = 10 minutes par algo)
#   julia test.jl 30       -> Exécute avec 30s par algo pour un test rapide
#   julia test.jl 30 3     -> Exécute avec 30s par algo, 3 runs pour min/moy/max réel


include("src/data.jl")
include("src/heuristiques.jl")
include("src/voisinages.jl")
include("src/solution.jl")
include("src/metaheuristiques.jl")
include("src/VND_VNS.jl")

using Random
using Printf

dir = "data/graphs"

# Temps limite par algorithme et par instance (en secondes)
# 600 secondes = 10 minutes
const TEMPS_PAR_DEFAUT = 600.0
limite_temps = length(ARGS) >= 1 ? parse(Float64, ARGS[1]) : TEMPS_PAR_DEFAUT
nb_runs      = length(ARGS) >= 2 ? parse(Int, ARGS[2])     : 1

println("=" ^ 90)
println("   BENCHMARK GLOBAL DES MÉTAHEURISTIQUES (k-COLORATION)")
println("   Temps alloué : $(limite_temps)s | Répétitions par instance : $(nb_runs)")
println("=" ^ 90)

# Liste des instances DIMACS avec leur nombre de couleurs cibles k
# Format : (nom_fichier, k)
instances = [
    ("dsjc125.1.col.txt", 5),
    ("dsjc125.9.col.txt", 44),
    ("dsjc125.9.col.txt", 22),
    ("dsjc250.1.col.txt", 8),
    ("dsjc250.5.col.txt", 28),
    ("dsjc250.9.col.txt", 72),
    ("dsjc250.9.col.txt", 36),
    ("flat300_26_0.col.txt", 26),
    ("flat300_26_0.col.txt", 13),
    ("le450_15c.col.txt", 15),
    ("le450_15c.col.txt", 8),
    ("dsjc1000.5.col.txt", 86),
    ("dsjc1000.5.col.txt", 85),
    ("dsjc1000.5.col.txt", 84),
    ("dsjc1000.5.col.txt", 42),
    ("dsjc1000.9.col.txt", 224),
    ("dsjc1000.9.col.txt", 223),
    ("dsjc1000.9.col.txt", 222),
    ("dsjc1000.9.col.txt", 111),
    ("C2000.5.col.txt", 147),
    ("C2000.5.col.txt", 146),
    ("C2000.5.col.txt", 73),
    ("C4000.5.col.txt", 261),
    ("C4000.5.col.txt", 260),
    ("C4000.5.col.txt", 130)
]

# Fichiers de sortie
csv_global   = "resultats_benchmark.csv"
csv_detail   = "resultats_detailles.csv"

# Initialisation du CSV global
open(csv_global, "w") do f
    println(f, "Instance,Sommets,Aretes,k,DSATUR_Conflits,Recuit_Conflits,Recuit_Temps,Tabou_Conflits,Tabou_Temps,VND_Conflits,VND_Temps")
end

# Initialisation du CSV détaillé
open(csv_detail, "w") do f
    println(f, "Instance,n,m,k,Algorithme,Conflits_Min,Conflits_Moy,Conflits_Max,T_total_s,T_best_s,Solutions_par_sec")
end

# Tableaux de stockage pour la génération finale des tables détaillées par algo
tab_tabou   = []
tab_vns     = []
tab_descente = []
tab_recuit  = []

println("\nProgression du benchmark :\n")
@printf("%-16s | %-4s | %-7s | %-3s | %-6s | %-13s | %-13s | %-13s\n", 
        "Instance", "n", "m", "k", "DSATUR", "Recuit Simulé", "Rech. Tabou", "GVNS / VND")
println("-" ^ 95)

for (nom, k) in instances
    chemin = joinpath(dir, nom)
    A, adj, n, m = lecture_graphe_avec_voisins(chemin)
    nom_court = replace(basename(nom), ".col.txt" => "", ".col" => "")

    # 1. Heuristique initiale DSATUR
    t0_dsatur = time()
    sol_dsatur = dsatur(adj, k)
    c_dsatur = nb_conflits(sol_dsatur, adj)
    dur_dsatur = time() - t0_dsatur
    
    # 2. Descente locale dans V1 (Déterministe, 1 seul run)
    t0_desc = time()
    sol_desc, c_desc, _ = descente_VND(copy(sol_dsatur), adj, collect(1:k); max_plateau=0)
    dur_desc = time() - t0_desc
    vit_desc = round(Int, (length(sol_desc) * (k - 1)) / max(dur_desc, 1e-5))
    # Méthode déterministe : min = moy = max = c_desc
    push!(tab_descente, (nom_court, c_dsatur, c_desc, round(dur_desc; digits=2), round(dur_desc; digits=2), vit_desc))

    # 3. Recuit Simulé (Stochastique, répété nb_runs fois)
    scores_rs = Int[]
    dur_rs_tot = 0.0
    t_best_rs_tot = 0.0
    vit_rs_tot = 0.0
    for r in 1:nb_runs
        _, _, c_fin, _, dur, t_best, vit = recuit_simule(
            A, adj, k, 200, aleatoire, _1_echange, 0.99;
            limite_temps=limite_temps, log=false, full_output=true
        )
        push!(scores_rs, c_fin)
        dur_rs_tot += dur
        t_best_rs_tot += t_best
        vit_rs_tot += vit
    end
    c_rs_min = minimum(scores_rs)
    c_rs_moy = round(sum(scores_rs) / length(scores_rs); digits=1)
    c_rs_max = maximum(scores_rs)
    dur_rs   = round(dur_rs_tot / nb_runs; digits=1)
    t_best_rs = round(t_best_rs_tot / nb_runs; digits=2)
    vit_rs   = round(Int, vit_rs_tot / nb_runs)
    push!(tab_recuit, (nom_court, c_rs_min, c_rs_moy, c_rs_max, dur_rs, t_best_rs, vit_rs))

    # 4. Recherche Tabou (Stochastique, répétée nb_runs fois)
    densite = 2 * m / (n * (n - 1))
    i_dens = n <= 250 ? 1 : n <= 500 ? 2 : n <= 1000 ? 3 : n <= 2000 ? 4 : 5
    j_dens = densite <= 0.2 ? 1 : densite <= 0.6 ? 2 : 3
    len_tabou = [
        10 20 30
        30 40 50
        40 60 80
        50 70 90
        100 100 100
    ][i_dens, j_dens]

    scores_tab = Int[]
    dur_tab_tot = 0.0
    t_best_tab_tot = 0.0
    vit_tab_tot = 0.0
    for r in 1:nb_runs
        _, _, c_fin, dur, t_best, vit = recherche_tabou(
            A, adj, n, k, aleatoire, _p_echange, len_tabou;
            taille_echantillon=20, taille_voisinage=5,
            n_iter_max_sans_amelioration=2500, n_perturbation_max_sans_amelioration=5,
            limite_temps=limite_temps, log=false
        )
        push!(scores_tab, c_fin)
        dur_tab_tot += dur
        t_best_tab_tot += t_best
        vit_tab_tot += vit
    end
    c_tab_min = minimum(scores_tab)
    c_tab_moy = round(sum(scores_tab) / length(scores_tab); digits=1)
    c_tab_max = maximum(scores_tab)
    dur_tab   = round(dur_tab_tot / nb_runs; digits=1)
    t_best_tab = round(t_best_tab_tot / nb_runs; digits=1)
    vit_tab   = round(Int, vit_tab_tot / nb_runs)
    push!(tab_tabou, (nom_court, c_tab_min, c_tab_moy, c_tab_max, dur_tab, t_best_tab, vit_tab))

    # 5. GVNS / VND (Stochastique lors des secousses)
    scores_vnd = Int[]
    dur_vnd_tot = 0.0
    t_best_vnd_tot = 0.0
    vit_vnd_tot = 0.0
    for r in 1:nb_runs
        _, _, c_fin, dur, t_best, vit = VNS(
            A, k; adj=adj, max_iter=100000, k_max=50,
            limite_temps=limite_temps, log=false, full_output=true
        )
        push!(scores_vnd, c_fin)
        dur_vnd_tot += dur
        t_best_vnd_tot += t_best
        vit_vnd_tot += vit
        # Si 0 conflit est atteint dès la descente initiale déterministe, les runs suivants seront identiques
        if c_fin == 0 && t_best < 0.5
            for _ in (r+1):nb_runs
                push!(scores_vnd, 0)
                dur_vnd_tot += dur
                t_best_vnd_tot += t_best
                vit_vnd_tot += vit
            end
            break
        end
    end
    c_vnd_min = minimum(scores_vnd)
    c_vnd_moy = round(sum(scores_vnd) / length(scores_vnd); digits=1)
    c_vnd_max = maximum(scores_vnd)
    dur_vnd   = round(dur_vnd_tot / length(scores_vnd); digits=1)
    t_best_vnd = round(t_best_vnd_tot / length(scores_vnd); digits=1)
    vit_vnd   = round(Int, vit_vnd_tot / length(scores_vnd))
    push!(tab_vns, (nom_court, c_vnd_min, c_vnd_moy, c_vnd_max, dur_vnd, t_best_vnd, vit_vnd))

    # Affichage console en temps réel
    @printf("%-16s | %-4d | %-7d | %-3d | %-6d | %-4d (%4.1fs) | %-4d (%4.1fs) | %-4d (%4.1fs)\n", 
            nom_court, n, m, k, c_dsatur, 
            c_rs_min, dur_rs, 
            c_tab_min, dur_tab, 
            c_vnd_min, dur_vnd)

    # Sauvegarde CSV global
    open(csv_global, "a") do f
        println(f, "$nom_court,$n,$m,$k,$c_dsatur,$c_rs_min,$dur_rs,$c_tab_min,$dur_tab,$c_vnd_min,$dur_vnd")
    end

    # Sauvegarde CSV détaillé (une ligne par algo)
    open(csv_detail, "a") do f
        println(f, "$nom_court,$n,$m,$k,Descente_V1,$c_desc,$c_desc,$c_desc,$(round(dur_desc; digits=2)),$(round(dur_desc; digits=2)),$vit_desc")
        println(f, "$nom_court,$n,$m,$k,Recuit_Simule,$c_rs_min,$c_rs_moy,$c_rs_max,$dur_rs,$t_best_rs,$vit_rs")
        println(f, "$nom_court,$n,$m,$k,Recherche_Tabou,$c_tab_min,$c_tab_moy,$c_tab_max,$dur_tab,$t_best_tab,$vit_tab")
        println(f, "$nom_court,$n,$m,$k,GVNS_VND,$c_vnd_min,$c_vnd_moy,$c_vnd_max,$dur_vnd,$t_best_vnd,$vit_vnd")
    end
end

println("-" ^ 95)

println("Benchmark terminé avec succès !")
println("-> Résultats globaux    : '$csv_global'")
println("-> Résultats détaillés  : '$csv_detail'")
