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


## 5. Pistes :

- Utiliser DSATUR dans la Recherche Tabou :
  - **Situation actuelle :** Tabou démarre d'une solution aléatoire. C'est un choix qui permet de maximiser la diversité initiale et d'éviter d'enfermer la recherche dans un biais heuristique (une cuvette dans laquelle le minimum total ne se trouve pas forcément).
  - **Intérêt sur les grands graphes ($n \ge 1000$) :** Sur des instances denses comme `dsjc1000.5` ou `dsjc1000.9`, une initialisation aléatoire commence avec 2000 à 3000 conflits, ce qui oblige l'algorithme à passer plusieurs minutes rien que pour faire le tri initial. DSATUR commence directement autour de 350-450 conflits, ce qui offrirait potentiellement un gain de temps considérable. DSATUR classique est déterministe, Tabou démarrerait toujours de la même solution et explorerait toujours la même vallée lors des redémarrages. Pour l'intégrer efficacement, il faudrait utiliser un **DSATUR randomisé** (ex. tirer au sort parmi les 3 sommets les plus saturés ou parmi les meilleures couleurs disponibles).

- pour un graphe dense (p>=0.6 par exemple), on choisi un échantillnage aléatoire des commets en conflits pour les paires de V_2
