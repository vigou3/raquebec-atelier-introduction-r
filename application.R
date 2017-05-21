### Emacs: -*- coding: utf-8; fill-column: 62; comment-column: 27; -*-
##
## Copyright (C) 2017 Vincent Goulet
##
## Ce fichier fait partie du projet «R à Québec - Atelier
## d'introduction à R»
## http://github.com/vigou3/raquebec-atelier-introduction-r
##
## Cette création est mise à disposition selon le contrat
## Attribution-Partage dans les mêmes conditions 4.0
## International de Creative Commons.
## http://creativecommons.org/licenses/by-sa/4.0/

###
### FONCTION 'apply'
###

### Pour une matrice

## Création d'une matrice pour les exemples.
m <- matrix(sample(1:100, 20), nrow = 4, ncol = 5)

## Les fonctions 'rowSums', 'colSums', 'rowMeans' et
## 'colMeans' sont des raccourcis pour des utilisations
## fréquentes de 'apply'.
rowSums(m)                 # sommes par ligne
apply(m, 1, sum)           # idem, mais moins lisible
colMeans(m)                # moyennes par colonne
apply(m, 2, mean)          # idem, mais moins lisible

## Puisqu'il n'existe pas de fonctions comme 'rowMax' ou
## 'colProds', il faut utiliser 'apply'.
apply(m, 1, max)           # maximums par ligne
apply(m, 2, prod)          # produits par colonne

### Pour un tableau

## Création d'un tableau à trois dimensions pour les exemples.
a <- array(sample(1:20, 60, replace = TRUE), dim = 3:5)

## Il n'existe pas de fonctions internes pour effectuer des
## sommaires sur des tableaux, il faut toujours utiliser
## 'apply'.
##
## L'utilisation de 'apply' sur les tableaux devient
## rapidement déconcertante si l'on ne visualise pas bien son
## effet.
##
## Truc mnémotechnique: la ou les dimensions absentes de
## MARGIN sont celles qui disparaissent après le
## passage de 'apply'.
apply(a, 1, sum)           # sommes des tranches horizontales
sum(a[1, , ])              # équivalent pour la première somme

apply(a, 3, sum)           # sommes des tranches transversales
sum(a[, , 1])              # équivalent pour la première somme

apply(a, c(1, 2), sum)     # sommes des carottes horizontales
sum(a[1, 1, ])             # équivalent pour la première somme

apply(a, c(1, 3), sum)     # sommes des carottes transversales
sum(a[1, , 1])             # équivalent pour la première somme

apply(a, c(2, 3), sum)     # sommes des carottes verticales
sum(a[, 1, 1])             # équivalent pour la première somme

###
### FONCTION 'tapply'
###

## Le jeu de données 'airquality' livré avec R contient les
## mesures quotidiennes de la qualité de l'air à New York
## Daily entre mai et septembre 1973.
?airquality                # rubrique d'aide du jeu de données

## La colonne 'Temp' contient la température du jour et la
## colonne 'Month', le mois (sous forme d'entier de 5 à 9).
##
## La fonction 'tapply' permet de calculer facilement la
## température moyenne par mois.
tapply(airquality$Temp, airquality$Month, mean)

## Équivalent (sauf pour la présentation des résultats).
by(airquality$Temp, airquality$Month, mean)

###
### FONCTIONS 'lapply' ET 'sapply'
###

## La fonction 'lapply' applique une fonction à tous les
## éléments d'un vecteur ou d'une liste et retourne une liste,
## peu importe les dimensions des résultats.
##
## La fonction 'sapply' retourne un vecteur ou une matrice
## lorsque tous les résultats sont de la même longueur.
##
## Somme «interne» des éléments d'une liste.
(x <- list(1:10, c(-2, 5, 6), matrix(3, 4, 5)))
sum(x)                     # erreur
lapply(x, sum)             # sommes internes (liste)
sapply(x, sum)             # sommes internes (vecteur)

## Création de la suite 1, 1, 2, 1, 2, 3, 1, 2, 3, 4, ...,
## 1, 2, ..., 9, 10.
lapply(1:10, seq)          # sous forme de liste
unlist(lapply(1:10, seq))  # transformation en vecteur

## Création d'une liste formée de quatre échantillons
## aléatoires de tailles différentes.
##
## L'expression ci-dessous fait usage de l'argument '...' de
## 'lapply'. Sachant que la définition de la fonction 'sample'
## est:
##
##   sample(x, size, replace = FALSE, prob = NULL)
##
## pouvez-vous  décoder? Nous y reviendrons plus
## loin, ce qui compte pour le moment c'est simplement de
## l'exécuter.
(x <- lapply(c(8, 12, 10, 9),
             sample,
             x = 1:10, replace = TRUE))

## La fonction suivante calcule la moyenne arithmétique
## des données d'un vecteur 'x' supérieures à une valeur 'y'.
## On remarquera que cette fonction n'est pas vectorielle pour
## 'y', c'est-à-dire qu'elle n'est valide que lorsque 'y' est
## un vecteur de longueur 1.
fun <- function(x, y) mean(x[x > y])

## Pour effectuer ce calcul sur chaque élément de la liste
## 'x', nous pouvons utiliser 'sapply' plutôt que 'lapply',
## car chaque résultat est de longueur 1.
##
## Cependant, il faut passer la valeur de 'y' à la fonction
## 'fun'. C'est le rôle de l'argument '...' de 'sapply'.
sapply(x, fun, 7)          # moyennes des données > 7

## La fonction 'sapply' est aussi très utile pour vectoriser
## une fonction qui n'est pas vectorielle. Supposons que l'on
## veut généraliser la fonction 'fun' pour qu'elle accepte un
## vecteur de seuils 'y'.
fun2 <- function(x, y)
    sapply(y, function(y) mean(x[x > y]))

## Utilisation sur la liste 'x' avec trois seuils. Remarquez
## comment nous avons implicitement effectué deux boucles.
sapply(x, fun2, y = c(3, 5, 7))

###
### FONCTION 'mapply'
###

## Application de la fonction 'fun' sur les échantillons de la
## liste 'x' avec un seuil différent pour chacun.
mapply(fun, x, c(3, 5, 7, 7))

###
### FONCTION 'replicate'
###

## La fonction 'replicate' répète 'n' fois une expression
## quelconque.
##
## La fonction sert surtout pour la simulation.
##
## Par exemple, simuler dix échantillons aléatoires
## indépendants de longueur 12 requiert d'exécuter la même
## expression dix fois. C'est un travail pour 'replicate'. À
## noter que les échantillons se trouvent dans les colonnes de
## la matrice résultante.
replicate(10, sample(1:100, 12))
