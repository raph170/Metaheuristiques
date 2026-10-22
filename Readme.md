## 1. Heuristique dédiée pour trouver une $k$-coloration des sommets de $G$
 - Soit la liste des couleurs `C`
 - On classe les sommets de $G$ par ordre décroissant des degrés (test avec random aussi)
 - Pour chacun des sommets de $G$ (dans l'ordre croissant définit précédemment) : 
    + on attibue au sommet courant $s$ la couleur de `C` qui est le plus utiliée parmis celles disponibles (c'est-à-dire qu'aucun des sommets voisins de $s$ ne sont de cette couleur) (tester avec "moins utilisées" et "aléatoire" aussi)
 - On s'arrête si aucune couleur n'est disponible pour colorier le sommet courant ou si tous les sommets sont coloriés

La complexité est $O(n^2 * C)$ où n est le nombre de sommets et C le nombre de couleurs.

## 2. Structures de voisinage adaptées au problème

**Exemple :** Soit la solution courante $x=(1, 3, 2)$ pour les couleurs $c=(1, 2, 3)$
 - le voisinage *2-swap* est $V_{2s}(x) = {(3, 1, 2), (2, 3, 1), (1, 2, 3)}$
 - le voisinage *1-color* est $V_{1c}(x) = {(2, 3, 2), (3, 3, 2), (1, 1, 2), (1, 2, 2), (1, 3, 1), (1, 3, 3)}$
- le voisinage *2-color* est $V_{2c}(x) = {(2, 1, 1), (2, 1, 3), (2, 2, 1), (2, 2, 3), (3, 1, 1), (3, 1, 3), (3, 2, 1), (3, 2, 3)}$


d-satur -> algo avec décroissance des degrés
Se renseigner sur partial goal -> utilise représentation partielle de la coloration