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
const TEMPS_PAR_DEFAUT = 600.0
limite_temps = length(ARGS) >= 1 ? parse(Float64, ARGS[1]) : TEMPS_PAR_DEFAUT
nb_runs      = length(ARGS) >= 2 ? parse(Int, ARGS[2])     : 1

tester_recuit = false # Mettre à true pour inclure également le recuit simulé

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
csv_global = "resultats_benchmark_bis.csv"
csv_detail = "resultats_detailles_bis.csv"

# Initialisation du CSV global
open(csv_global, "w") do f
    println(f, "Instance,Sommets,Aretes,k,DSATUR_Conflits,Tabou_Std_Conflits,Tabou_Std_Temps,Tabou_Carre_Conflits,Tabou_Carre_Temps,VNS_Std_Conflits,VNS_Std_Temps,VNS_Carre_Conflits,VNS_Carre_Temps")
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
@printf("%-16s | %-4s | %-7s | %-3s | %-6s | %-15s | %-15s | %-15s | %-15s\n", 
        "Instance", "n", "m", "k", "DSATUR", "Tabou (std)", "Tabou (carré)", "VNS (std)", "VNS (carré)")
println("-" ^ 120)

for (nom, k) in instances
    chemin = joinpath(dir, nom)
    A, adj, n, m = lecture_graphe_avec_voisins(chemin)
    nom_court = replace(basename(nom), ".col.txt" => "", ".col" => "")

    # 1. Heuristique initiale DSATUR (Déterministe)
    t0_dsatur = time()
    sol_dsatur = dsatur(adj, k)
    c_dsatur = nb_conflits(sol_dsatur, adj)
    dur_dsatur = time() - t0_dsatur
    
    # 2. Descente locale dans V1 (Déterministe, 1 seul run)
    t0_desc = time()
    sol_desc, c_desc, _ = descente_VND(copy(sol_dsatur), adj, collect(1:k); max_plateau=0)
    dur_desc = time() - t0_desc
    vit_desc = round(Int, (length(sol_desc) * (k - 1)) / max(dur_desc, 1e-5))

    # 3. Recherche Tabou - Objectif Classique
    scores_tab_std = Int[]
    dur_tab_std_tot = 0.0
    t_best_tab_std_tot = 0.0
    vit_tab_std_tot = 0.0
    for r in 1:nb_runs
        sol, _, c_fin, dur, t_best, vit = recherche_tabou(
            adj, n, k, aleatoire, _p_echange, nothing;
            type_obj="classique",
            taille_echantillon=20, taille_voisinage=5,
            n_iter_max_sans_amelioration=10000, n_perturbation_max_sans_amelioration=3,
            limite_temps=limite_temps, log=false
        )
        push!(scores_tab_std, c_fin)
        dur_tab_std_tot += dur
        t_best_tab_std_tot += t_best
        vit_tab_std_tot += vit
    end
    c_tab_std_min = minimum(scores_tab_std)
    c_tab_std_moy = round(sum(scores_tab_std) / length(scores_tab_std); digits=1)
    c_tab_std_max = maximum(scores_tab_std)
    dur_tab_std   = round(dur_tab_std_tot / nb_runs; digits=1)
    t_best_tab_std = round(t_best_tab_std_tot / nb_runs; digits=1)
    vit_tab_std   = round(Int, vit_tab_std_tot / nb_runs)

    # 4. Recherche Tabou - Objectif Carré
    scores_tab_carre = Int[]
    dur_tab_carre_tot = 0.0
    t_best_tab_carre_tot = 0.0
    vit_tab_carre_tot = 0.0
    for r in 1:nb_runs
        sol, _, _, dur, t_best, vit = recherche_tabou(
            adj, n, k, aleatoire, _p_echange, nothing;
            type_obj="pondéré",
            taille_echantillon=20, taille_voisinage=5,
            n_iter_max_sans_amelioration=10000, n_perturbation_max_sans_amelioration=3,
            limite_temps=limite_temps, log=false
        )
        c_reel = nb_conflits(sol, adj)
        push!(scores_tab_carre, c_reel)
        dur_tab_carre_tot += dur
        t_best_tab_carre_tot += t_best
        vit_tab_carre_tot += vit
    end
    c_tab_carre_min = minimum(scores_tab_carre)
    c_tab_carre_moy = round(sum(scores_tab_carre) / length(scores_tab_carre); digits=1)
    c_tab_carre_max = maximum(scores_tab_carre)
    dur_tab_carre   = round(dur_tab_carre_tot / nb_runs; digits=1)
    t_best_tab_carre = round(t_best_tab_carre_tot / nb_runs; digits=1)
    vit_tab_carre   = round(Int, vit_tab_carre_tot / nb_runs)

    # 5. GVNS / VND - Objectif Classique
    scores_vnd_std = Int[]
    dur_vnd_std_tot = 0.0
    t_best_vnd_std_tot = 0.0
    vit_vnd_std_tot = 0.0
    for r in 1:nb_runs
        _, _, c_fin, dur, t_best, vit = VNS(
            A, k; adj=adj, max_iter=100000, k_max=100,
            limite_temps=limite_temps, log=false, full_output=true, type_obj="classique"
        )
        push!(scores_vnd_std, c_fin)
        dur_vnd_std_tot += dur
        t_best_vnd_std_tot += t_best
        vit_vnd_std_tot += vit
        # Si 0 conflit atteint dès la descente déterministe
        if c_fin == 0 && t_best < 0.5
            for _ in (r+1):nb_runs
                push!(scores_vnd_std, 0)
                dur_vnd_std_tot += dur
                t_best_vnd_std_tot += t_best
                vit_vnd_std_tot += vit
            end
            break
        end
    end
    c_vnd_std_min = minimum(scores_vnd_std)
    c_vnd_std_moy = round(sum(scores_vnd_std) / length(scores_vnd_std); digits=1)
    c_vnd_std_max = maximum(scores_vnd_std)
    dur_vnd_std   = round(dur_vnd_std_tot / length(scores_vnd_std); digits=1)
    t_best_vnd_std = round(t_best_vnd_std_tot / length(scores_vnd_std); digits=1)
    vit_vnd_std   = round(Int, vit_vnd_std_tot / length(scores_vnd_std))

    # 6. GVNS / VND - Objectif Carré
    scores_vnd_carre = Int[]
    dur_vnd_carre_tot = 0.0
    t_best_vnd_carre_tot = 0.0
    vit_vnd_carre_tot = 0.0
    for r in 1:nb_runs
        _, _, c_fin, dur, t_best, vit = VNS(
            A, k; adj=adj, max_iter=100000, k_max=100,
            limite_temps=limite_temps, log=false, full_output=true, type_obj="pondéré"
        )
        push!(scores_vnd_carre, c_fin)
        dur_vnd_carre_tot += dur
        t_best_vnd_carre_tot += t_best
        vit_vnd_carre_tot += vit
        if c_fin == 0 && t_best < 0.5
            for _ in (r+1):nb_runs
                push!(scores_vnd_carre, 0)
                dur_vnd_carre_tot += dur
                t_best_vnd_carre_tot += t_best
                vit_vnd_carre_tot += vit
            end
            break
        end
    end
    c_vnd_carre_min = minimum(scores_vnd_carre)
    c_vnd_carre_moy = round(sum(scores_vnd_carre) / length(scores_vnd_carre); digits=1)
    c_vnd_carre_max = maximum(scores_vnd_carre)
    dur_vnd_carre   = round(dur_vnd_carre_tot / length(scores_vnd_carre); digits=1)
    t_best_vnd_carre = round(t_best_vnd_carre_tot / length(scores_vnd_carre); digits=1)
    vit_vnd_carre   = round(Int, vit_vnd_carre_tot / length(scores_vnd_carre))

    # 7. Recuit Simulé (Optionnel si tester_recuit=true)
    if tester_recuit
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
    end

    # Affichage console en temps réel
    @printf("%-16s | %-4d | %-7d | %-3d | %-6d | %-4d (%4.1fs) | %-4d (%4.1fs) | %-4d (%4.1fs) | %-4d (%4.1fs)\n", 
            nom_court, n, m, k, c_dsatur, 
            c_tab_std_min, dur_tab_std,
            c_tab_carre_min, dur_tab_carre,
            c_vnd_std_min, dur_vnd_std,
            c_vnd_carre_min, dur_vnd_carre)

    # Sauvegarde CSV global
    open(csv_global, "a") do f
        println(f, "$nom_court,$n,$m,$k,$c_dsatur,$c_tab_std_min,$dur_tab_std,$c_tab_carre_min,$dur_tab_carre,$c_vnd_std_min,$dur_vnd_std,$c_vnd_carre_min,$dur_vnd_carre")
    end

    # Sauvegarde CSV détaillé (une ligne par algorithme et variante d'objectif)
    open(csv_detail, "a") do f
        println(f, "$nom_court,$n,$m,$k,DSATUR,$c_dsatur,$c_dsatur,$c_dsatur,$(round(dur_dsatur; digits=2)),$(round(dur_dsatur; digits=2)),0")
        println(f, "$nom_court,$n,$m,$k,Descente_V1,$c_desc,$c_desc,$c_desc,$(round(dur_desc; digits=2)),$(round(dur_desc; digits=2)),$vit_desc")
        println(f, "$nom_court,$n,$m,$k,Tabou_Classique,$c_tab_std_min,$c_tab_std_moy,$c_tab_std_max,$dur_tab_std,$t_best_tab_std,$vit_tab_std")
        println(f, "$nom_court,$n,$m,$k,Tabou_Carre,$c_tab_carre_min,$c_tab_carre_moy,$c_tab_carre_max,$dur_tab_carre,$t_best_tab_carre,$vit_tab_carre")
        println(f, "$nom_court,$n,$m,$k,GVNS_VND_Classique,$c_vnd_std_min,$c_vnd_std_moy,$c_vnd_std_max,$dur_vnd_std,$t_best_vnd_std,$vit_vnd_std")
        println(f, "$nom_court,$n,$m,$k,GVNS_VND_Carre,$c_vnd_carre_min,$c_vnd_carre_moy,$c_vnd_carre_max,$dur_vnd_carre,$t_best_vnd_carre,$vit_vnd_carre")
        if tester_recuit
            println(f, "$nom_court,$n,$m,$k,Recuit_Simule,$c_rs_min,$c_rs_moy,$c_rs_max,$dur_rs,$t_best_rs,$vit_rs")
        end
    end
end

println("-" ^ 95)

println("Benchmark terminé avec succès !")
println("-> Résultats globaux    : '$csv_global'")
println("-> Résultats détaillés  : '$csv_detail'")
