## 1. Heuristique dédiée pour trouver une $k$-coloration des sommets de $G$
 - Soit la liste des couleurs `C`
 - On classe les sommets de $G$ par ordre décroissant des degrés (test avec random aussi)
 - Pour chacun des sommets de $G$ (dans l'ordre croissant définit précédemment) : 
    + on attibue au sommet courant $s$ la couleur de `C` qui est le plus utiliée parmis celles disponibles (c'est-à-dire qu'aucun des sommets voisins de $s$ ne sont de cette couleur) (tester avec "moins utilisées" et "aléatoire" aussi)
 - On s'arrête si aucune couleur n'est disponible pour colorier le sommet courant ou si tous les sommets sont coloriés

La complexité est $O(n^2 * C)$ où n est le nombre de sommets et C le nombre de couleurs.

## 2. Structures de voisinage adaptées au problème

 - Voisinage où on échange les couleurs de deux sommets (*2-swap*) : pas une bonne idée car avec ce voisinage, le nombre de somments de la couleur i ne varie pas, ce qui peut être problématique
 - Voisinage où on change la couleur de $k$ sommets (*k-color*)

**Exemple :** Soit la solution courante $x=(1, 3, 2)$ pour les couleurs $c=(1, 2, 3)$
 - le voisinage *2-swap* est $V_{2s}(x) = \{(3, 1, 2), (2, 3, 1), (1, 2, 3)\}$
 - le voisinage *1-color* est $V_{1c}(x) = \{(2, 3, 2), (3, 3, 2), (1, 1, 2), (1, 2, 2), (1, 3, 1), (1, 3, 3)\}$
 - le voisinage *2-color* est $V_{2c}(x) = \{(2, 1, 1), (2, 1, 3), (2, 2, 1), (2, 2, 3), (3, 1, 1), (3, 1, 3), (3, 2, 1), (3, 2, 3)\}$

## 3. Pistes pour une heuristique plus poussée

Pour aller plus loin que le simple tri par degré décroissant :

- **DSATUR (Degré de saturation) :**
  - Au lieu d'un tri statique au début, on choisit dynamiquement à chaque étape le sommet qui a le plus de couleurs différentes déjà utilisées par ses voisins

- **à tester :**
  - Heuristique qui favorise les cliques de taille maximale : on sélectionne une clique, puis une deuxième dans le graphe restant, ...

## 4. Métaheuristiques de k-colorations

### A. Recherche à Voisinage Variable (VNS)
*(Très simple à mettre en place avec les voisinages déjà codés)*

### B. Recherche Tabou
- **Objectif :** minimiser le nombre d'arêtes en conflit pour un nombre fixé de couleurs.
- **Voisinage en conflits :** on ne teste que les sommets qui ont au moins un voisin de même couleur. On applique la transformation *1-color*.
- **Tabou :**
  - Si on passe le sommet $s$ de la couleur $c_1$ à $c_2$, le couple $(s, c_1)$ devient "tabou" pendant $T$ itérations (T optimal à définir --> aléatoire ? dynamique ?).

### C. Algorithme Génétique
- **Population :** un ensemble de colorations dans lequel on essaie de mpinimiser le nombre de conflits
- **Mutation :**
  - On modifier aléatoirement la couleur de sommets en conflit (voisin *1-color* ou *2-color*).


## Suivi du projet
 - Implémentation VNS :
   + améliorations faites : 
     - on utilise finalament une liste d'adjacence pour trouver les conflits en temps constant
     - la descente locale et les perturbations n'exlporent que les modifications de sommets impliqués dans des conflits (pas tous)
     - Si $k$ est supérieur au nombre de sommets en conflit, on prend tous les sommets en conflit ET on complète avec des sommets voisins
     - au lieu d'un tri sur les degrés statiques, on implémente DSATUR, qui permet de choisir dynamiquement à chaque pas le sommet qui a le plus grand nombre de couleurs différentes parmi ses voisins
     - autoriser les mouvements sur un plateau (quand le delta d'amélioration est nul) avec détection anti-cycle
     - **Stratégie Best Improvement** avec $\Delta$-évaluation : au lieu de s'arrêter au premier voisin améliorant, on teste tous les sommets en conflit et toutes les couleurs pour appliquer le meilleur mouvement possible ($\min \Delta$)
     - **Descente à Voisinage Variable (VND)** : couplage de $V_1$ (1-color) et $V_2$ (2-color ciblé) au sein de la descente locale. Dès qu'un minimum local strict en 1-color est atteint, le 2-color débloque la situation et renvoie immédiatement vers $V_1$
     - **Backtracking historique** : mémorisation des meilleures solutions records et retour en arrière séquentiel après 4 stagnations consécutives
   + améliorations à ajouter :
     - un tabou

     
## 5. Résultats expérimentaux

### Tableau des meilleurs résultats

| Instance | Sommets ($n$) | Arêtes ($m$) | Couleurs cibles ($k$) | Heuristique Initiale (DSATUR) | Meilleur Résultat VNS (Conflits) | Statut de la solution |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **`dsjc125.1.col`** | 125 | 736 | **5** | 10 *(37 au glouton)* | **0** *(1 itér.)* | **Optimal prouvé** ($\chi = 5$) |
| **`dsjc125.9.col`** | 125 | 6 961 | **44** | 20 | **0** *(1 itér.)* | **Optimal prouvé** ($\chi = 44$) |
| **`dsjc250.1.col`** | 250 | 3 218 | **8** | 50 | **0** *(1983 itér.)* | **Optimal prouvé** ($\chi = 8$) |
| **`dsjc250.5.col`** | 250 | 15 668 | **28** | 93 | **7** | **99,96 %** arêtes valides |
| **`dsjc250.9.col`** | 250 | 55 794 | **72** | 62 | **0** *(1222 itér.)* | **Optimal prouvé** ($\chi = 72$) |
| **`flat300_26_0.col`** | 300 | 21 633 | **26** | 206 | **64** | $-68,9\%$ |
| **`le450_15c.col`** | 450 | 16 680 | **15** | 317 | **163** | $-48,6\%$ |
| **`dsjc1000.5.col`** | 1 000 | 249 826 | **83** | 467 | **110** *(itér. 989)* | $-76,4\%$ |
