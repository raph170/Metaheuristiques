## Architecture globale
Le code est décomposé en plusieurs fichiers julia : 
**Dossier src :**
- main.jl : fichier principal pour lancer les résolutions en choisissant la méthode souhaitée.
- metaheuristiques.jl et VND_VNS.jl : contient les fonctions des différentes métaheuristiques utilisées : recuit simulé, recherche tabou, VND/VNS.
- heuristiques.jl : contient les fonctions des différentes heuristiques utilisées (aléatoire, glouton, glouton par degrès croissants, Dsatur)
- voisinages.jl : contient les fonctions permettant de déterminer les différents voisinages d'une solution. Soit l'ensemble complet, soit un seul voisin.
- solution.jl : Pour gérer les conflits d'une solution, notamment le calcul des 2 fonctions objectifs : nombre de conflits et nombre de conflits pondérés.
- data.jl : pour lire les instances.

**Dossier principal :**
- test.jl :Pour réaliser des tests automatisés de toutes les métaheuristiques sur les instances
##### Usage :
- julia test.jl          -> Exécute avec le temps par défaut (600s = 10 minutes par algo)
- julia test.jl 30       -> Exécute avec 30s par algo pour un test rapide
- julia test.jl 30 3     -> Exécute avec 30s par algo, 3 runs pour min/moy/max réel


## Lancement d'une résolution
Pour lancer une résolution, il suffit de sélectionner le nom du fichier (ie du graphe) et le nombre de couleurs dans le fichier main.jl. Il faut également sélectionner la métaheuristique choisie pour la résolution ainsi que le type de fonction objectif.

D'autres paramètres comme le temps limite de résolution ou l'heuristique choisie pour déterminer la solution initiale peuvent également être modifiés.

Enfin certains arguments propres à chaque métaheuristique peuvent être modifiés lors de l'appel à ces fonctions (log : true/false, température T pour le recuit simulé, len_tabou pour la recherche tabou, k_max pour la VNS,...)

Voici un exemple de quelques paramètres choisis : 

#### Choix du graphe (a selectionner)
nom_fichier = "dsjc125.1.col.txt"

#### Choix du nombre de couleurs (a selectionner) :
k = couleurs[nom_fichier][1]+1

#### Choix de l'heuristique pour la solution initiale (a selectionner)
heuristique = aleatoire

#### Limite de temps (a selectionner)
limite_temps = 120

#### Choix de la méthode de résolution (a selectionner) :
meta_heuristique = "recherche tabou"

Il suffit ensuite de lancer l'exécution du fichier main.jl
